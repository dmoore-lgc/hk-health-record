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
        let procedures = HKObjectType.clinicalType(forIdentifier: .procedureRecord)!
        let allergies = HKObjectType.clinicalType(forIdentifier: .allergyRecord)!
        let types = Set([medications, conditions, procedures, allergies])
        
        guard let healthStore = self.healthStore else { return completion(false)}
        
        healthStore.requestAuthorization(toShare: nil, read: types) { (success, error) in
            guard success else {
                print(error!)
                return
            }
        }
    }
    
    func getUserSamples(identifier: HKClinicalTypeIdentifier,completion: @escaping ([String]) -> Void) {
        let type = HKObjectType.clinicalType(forIdentifier: identifier)!
        let query = HKSampleQuery(sampleType: type,
                                  predicate: nil,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: []) { (query, samples, error) in
            let samplesArr = samples as? [HKClinicalRecord]
            let arr = samplesArr!
            var fhirResources = [HKFHIRResource]()
            for index in 0 ..< arr.count {
                print(arr[index].displayName)
                fhirResources.append(arr[index].fhirResource!)
            }
            var output = [String]()
            for elem in self.deserializeJSON(input: fhirResources, identifier: identifier) {
                if identifier == .medicationRecord {
                    self.convertSCDCtoIN(rxcui: elem!) { ingredient in
                        sleep(1)
                        output.append(ingredient!)
                    }
                } else {
                    output.append(elem!)
                }
            }
            //sleep(2)
            print(output)
            completion(output)
        }
        healthStore!.execute(query)
    }
    
    func deserializeJSON(input: [HKFHIRResource], identifier: HKClinicalTypeIdentifier) -> [String?] {
        var results = [String?]()
        var flag = false
        var inp = ""
        switch identifier {
        case .allergyRecord:
            inp = "substance"
        case .medicationRecord:
            inp = "medicationCodeableConcept"
        case .procedureRecord:
            flag = true
        default:
            flag = true
        }
        for index in 0 ..< input.count {
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: input[index].data, options: JSONSerialization.ReadingOptions.mutableContainers)
                if let jsonDict = jsonObject as? NSDictionary {
                    if flag {
                        let result = ((jsonDict["code"] as? NSDictionary)!["coding"] as? NSArray)![0] as? NSDictionary
                        if result!["code"] != nil {
                            results.append(String(describing: result!["code"]!))
                        }
                    }
                    else if let jsonDict = jsonDict["\(inp)"] as? NSDictionary {
                        let result = (jsonDict["coding"]! as? NSArray)![0] as? NSDictionary
                        if result!["code"] != nil {
                            results.append(String(describing: result!["code"]!))
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
    
    func compareArrays(uMeds: [String], dMeds: [String], disease: String) -> String {
        for uMed in uMeds {
            for dMed in dMeds {
                if uMed == dMed {
                    return ("\(uMed) treats \(disease).")
                }
            }
        }
        return ("No matches found.")
    }
}
