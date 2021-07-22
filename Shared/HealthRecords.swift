//
//  HealthRecords.swift
//  hk-test
//
//  Created by David Moore on 08/07/2021.
//

import Foundation
import HealthKit
import Alamofire
import SWXMLHash

class HealthRecords {
    var healthStore: HKHealthStore?
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        
        let medications = HKObjectType.clinicalType(forIdentifier: .medicationRecord)!
        let conditions = HKObjectType.clinicalType(forIdentifier: .conditionRecord)!
        let types = Set([medications, conditions])
        
        guard let healthStore = self.healthStore else { return completion(false)}
        
        healthStore.requestAuthorization(toShare: nil, read: types) { (success, error) in
            guard success else {
                print(error!)
                return
            }
        }
    }
    
    func getUserMeds(completion: @escaping ([String]) -> Void) {
        let medicationType = HKObjectType.clinicalType(forIdentifier: .medicationRecord)!
        let query = HKSampleQuery(sampleType: medicationType,
                                  predicate: nil,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: []) { (query, samples, error) in
            let medicationSamples = samples as? [HKClinicalRecord]
            let ms = medicationSamples!
            var fhirResources = [HKFHIRResource]()
            for index in 0 ..< ms.count {
                //print(ms[index].displayName)
                print(ms[index].displayName)
                fhirResources.append(ms[index].fhirResource!)
            }
            // For testing purposes the request authorization function drives the deserialization functions and prints them to console.
            var hkMeds = [String]()
            //print(self.deserializeJSON(input: fhirResources))
            for elem in self.deserializeJSON(input: fhirResources) {
                self.convertSCDCtoIN(rxcui: elem!) { ingredient in
                    hkMeds.append(ingredient!)
                }
            }
            //  When sleep isn't called the following error is returned - "nw_protocol_get_quic_image_block_invoke dlopen libquic failed"
            sleep(2)
            print("User medication RXCUIs are: \(hkMeds)")
            completion(hkMeds)
        }
        healthStore!.execute(query)
    }
    
    // Initially implemented a solution which returns an array of tuples consisting of the provider (RxNorm) and the RXCUI code.
    // As far as I am aware the only provider used for medications is RxNorm so it is only the RXCUI code which is needed.
    func deserializeJSONToTuples(input: [HKFHIRResource]) -> [(Any?, Any?)] {
        var tuples = [(Any?, Any?)]()
        for index in 0 ..< input.count {
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: input[index].data, options: JSONSerialization.ReadingOptions.mutableContainers)
                if let jsonDict = jsonObject as? NSDictionary {
                    //print (jsonDict)
                    if let jsonDict = jsonDict["medicationCodeableConcept"]! as? NSDictionary {
                        let jsonArray = jsonDict["coding"]! as? NSArray
                        let jsonDict = jsonArray![0] as? NSDictionary
                        tuples.append((jsonDict!["system"], jsonDict!["code"]))
                    }
                }
            } catch {
                print(error)
            }
        }
        return tuples
    }
    
    // This is the adjusted function which returns a list of RXCUI codes instead. These codes will then need to be checked against an array of RXCUI
    // codes relating to the disease/condition relevant to the questionnaire question.
    func deserializeJSON(input: [HKFHIRResource]) -> [String?] {
        var results = [String?]()
        for index in 0 ..< input.count {
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: input[index].data, options: JSONSerialization.ReadingOptions.mutableContainers)
                if let jsonDict = jsonObject as? NSDictionary {
                    //print (jsonDict)
                    if let jsonDict = jsonDict["medicationCodeableConcept"]! as? NSDictionary {
                        let jsonArray = jsonDict["coding"]! as? NSArray
                        let jsonDict = jsonArray![0] as? NSDictionary
                        if jsonDict!["code"] != nil {
                            results.append(String(describing: jsonDict!["code"]!))
                        }
                    }
                }
            } catch {
                print(error)
            }
        }
        return results
    }
    
    func convertSCDCtoIN (rxcui: String, completionHandler: @escaping (String?) -> Void) {
        DispatchQueue.main.async {
            let url = "https://rxnav.nlm.nih.gov/REST/rxcui/\(rxcui)/allrelated.xml"
            AF.request(url).responseData { response in
                switch response.result {
                case .success(let value):
                    let xml = SWXMLHash.parse(value)
                    var result = ""
                    for elem in xml["rxnormdata"]["allRelatedGroup"]["conceptGroup"].all {
                        if elem["tty"].element!.text == "IN" {
                            result = elem["conceptProperties"]["rxcui"].element!.text
                            break
                        }
                    }
                    completionHandler(result)
                case .failure(let error):
                    print(error)
                    completionHandler(nil)
                }
            }
        }
    }
    
    func fetchMedicationsForDisease(disease: String, completionHandler: @escaping ([String]?) -> Void) {
        let url1 = "https://rxnav.nlm.nih.gov/REST/rxclass/class/byName.xml?className=\(disease)&classTypes=DISEASE"
        AF.request(url1).responseData { response in
            switch response.result {
            case .success(let value):
                // API returns XML format which can be parsed with SWXMLHash pod.
                let xml = SWXMLHash.parse(value)
                if xml["rxclassdata"]["rxclassMinConceptList"]["rxclassMinConcept"]["classId"].element != nil {
                    let diseaseCode =  xml["rxclassdata"]["rxclassMinConceptList"]["rxclassMinConcept"]["classId"].element!.text
                    let url2 = "https://rxnav.nlm.nih.gov/REST/rxclass/classMembers.xml?classId=\(diseaseCode)&relaSource=MEDRT&rela=may_treat&direct=0&ttys=IN"
                    AF.request(url2).responseData { response in
                        switch response.result {
                        case .success(let value):
                            var output = [String]()
                            let xml = SWXMLHash.parse(value)
                            for elem in xml["rxclassdata"]["drugMemberGroup"]["drugMember"].all {
                                //print("\(elem["minConcept"]["name"].element!.text): \(elem["minConcept"]["rxcui"].element!.text)")
                                output.append(elem["minConcept"]["rxcui"].element!.text)
                            }
                            completionHandler(output)
                        case .failure:
                            print("Hello")
                            completionHandler([])
                        }
                    }
                } else {
                    completionHandler([])
                }
            case .failure:
                completionHandler([])
            }
        }
    }
    
    func compareArrays(uMeds: [String], dMeds: [String], disease: String) {
        for uMed in uMeds {
            for dMed in dMeds {
                if uMed == dMed {
                    print("\(uMed) treats \(disease).\n")
                    return
                }
            }
        }
        print("No matches found.")
    }
}
