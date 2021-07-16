//
//  HealthRecords.swift
//  hk-test
//
//  Created by David Moore on 08/07/2021.
//

import Foundation
import HealthKit

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
            let medicationType = HKObjectType.clinicalType(forIdentifier: .medicationRecord)!
            let query = HKSampleQuery(sampleType: medicationType,
                                      predicate: nil,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: []) { (query, samples, error) in
                let medicationSamples = samples as? [HKClinicalRecord]
                let ms = medicationSamples!
                var fhirResources = [HKFHIRResource]()
                for index in 0 ..< ms.count {
                    print(ms[index].displayName)
                    fhirResources.append(ms[index].fhirResource!)
                }
                // For testing purposes the request authorization function drives the deserialization functions and prints them to console.
                print(self.deserializeJSONToTuples(input: fhirResources))
                print(self.deserializeJSON(input: fhirResources))
            }
            healthStore.execute(query)
        }
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
    func deserializeJSON(input: [HKFHIRResource]) -> [Any?] {
        var result = [Any?]()
        for index in 0 ..< input.count {
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: input[index].data, options: JSONSerialization.ReadingOptions.mutableContainers)
                if let jsonDict = jsonObject as? NSDictionary {
                    //print (jsonDict)
                    if let jsonDict = jsonDict["medicationCodeableConcept"]! as? NSDictionary {
                        let jsonArray = jsonDict["coding"]! as? NSArray
                        let jsonDict = jsonArray![0] as? NSDictionary
                        result.append(jsonDict!["code"])
                    }
                }
            } catch {
                print(error)
            }
        }
        return result
    }
}
