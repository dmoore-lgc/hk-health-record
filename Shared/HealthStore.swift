//
//  HealthStore.swift
//  hk-test
//
//  Created by David Moore on 30/06/2021.
////
//
//import Foundation
//import HealthKit
//
//class HealthStore {
//
//    var healthStore: HKHealthStore?
//    var querySteps: HKStatisticsCollectionQuery?
//    var queryHeight: HKSampleQuery?
//
//    init() {
//        if HKHealthStore.isHealthDataAvailable() {
//            healthStore = HKHealthStore()
//        }
//    }
//
//    // Completion handler - Creates a closure which will be fired when the request for authorisation is completed.
//    // That closure will give access to either success or failure based on the boolean true or false being returned.
//    func requestAuthorization(completion: @escaping (Bool) -> Void) {
//
//        // Defining all the data types we want to access. This could probably be done in a set.
//        //
//        let stepType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
//        let sexType = HKCharacteristicType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!
//        let heightType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!
//        let weightType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
//        // Apparently DOB/Age isn't asked in questionnaire so this probably isn't necessary.
//        //let dobType = HKCharacteristicType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)!
//
//        // Unwrapping healthStore, if not return the completion value false.
//        guard let healthStore = self.healthStore else { return completion(false)}
//
//        healthStore.requestAuthorization(toShare: nil, read: [stepType, sexType, heightType, weightType]) { (success, error) in
//            completion(success)
//        }
//    }
//    // Completion handler will make sure a HK statistics collection is returned
//    func calculateSteps(completion: @escaping (HKStatisticsCollection?) -> Void) {
//
//        // Reusing the above stepType definition to choose to collect stepCount.
//        let stepType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
//
//        // Only want step count from last 7 days.
//        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
//
//        // Setting up anchor date to define when the day actually starts/ends using extension to Date class defined below.
//        let anchorDate = Date.mondayAt12AM()
//
//        let daily = DateComponents(day: 1)
//
//        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
//
//        querySteps = HKStatisticsCollectionQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: anchorDate, intervalComponents: daily)
//
//        querySteps!.initialResultsHandler = { query, statisticsCollection, error in
//            completion(statisticsCollection)
//        }
//
//        if let healthStore = healthStore, let query = self.querySteps {
//            healthStore.execute(query)
//        }
//    }
//
////    func returnSex() throws -> HKBiologicalSexObject? {
////        //let sexType = HKCharacteristicType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!
////        do {
////            let biologicalSex = try healthStore?.biologicalSex()
////            return biologicalSex?.biologicalSex
////        }
////    }
//
//    func biologicalSex(completion: @escaping ((_ biologicalSex: String?) -> Void)) {
//        let biologicalSex = try? healthStore?.biologicalSex()
//        if biologicalSex == nil {
//            completion(nil)
//        } else {
//            completion(getSex(biologicalSex: biologicalSex!.biologicalSex))
//        }
//    }
//
//    private func getSex(biologicalSex: HKBiologicalSex) -> String? {
//        switch biologicalSex.rawValue{
//            case 0:
//                return nil
//            case 1:
//                return "Female"
//            case 2:
//                return "Male"
//            case 3:
//                return "Other"
//            default:
//                return nil
//        }
//    }
//
//    //func bodyMassKg(completion: @escaping ((_ bodyMass: Int?, _ date: Date?) -> Void)) {
//    func bodyMassKg(completion: @escaping ((_ bodyMass: Int?) -> Void)) {
//        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
//        let weightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
//        let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, results, error) in
//            if let result = results?.first as? HKQuantitySample {
//                let bodyMassKg = result.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
//                // Returns a touple of bodyMass in kg rounded up and the date this weight was taken from.
//                // The actual implementation won't need date so will need to be changed.
//                completion(Int(bodyMassKg.rounded()))
//                return
//            }
//                //no data
//            completion(nil)
//        }
//        healthStore!.execute(query)
//    }
//
//    //func heightCm(completion: @escaping ((_ height: Int?, _ date: Date?) -> Void)) {      Initial implementation which returned the date the height was taken from
//    func heightCm(completion: @escaping ((_ height: Int?) -> Void)) {
//        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
//        let heightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!
//        let query = HKSampleQuery(sampleType: heightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, results, error) in
//            if let result = results?.first as? HKQuantitySample {
//                let heightCm = result.quantity.doubleValue(for: HKUnit.meterUnit(with: .centi))
//                // Returns a touple of height in cm rounded up and the date this weight was taken from.
//                completion(Int(heightCm.rounded()))
//                return
//            }
//                //no data
//            completion(nil)
//        }
//        healthStore!.execute(query)
//    }
//}
//
//extension Date {
//    static func mondayAt12AM() -> Date {
//        return Calendar(identifier: .iso8601).date(from: Calendar(identifier: .iso8601).dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
//    }
//}
