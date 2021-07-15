//
//  ContentView.swift
//  Shared
//
//  Created by David Moore on 30/06/2021.
//

import SwiftUI
import HealthKit
import Alamofire
import SWXMLHash

struct ContentView: View {
    var body: some View {
        Button {
            fetchMedicationsForDisease(disease: "dementia")
            if let healthStore = healthStore {
                healthStore.requestAuthorization { success in
                    print(success)
                }
            }
        } label: {
            Text("Test HealthKit")
                .fontWeight(.bold)
                .font(.title)
                .padding()
                .background(Color.blue)
                .cornerRadius(40)
                .foregroundColor(.white)
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(Color.blue, lineWidth: 5)
                )
        }

    }
    private var healthStore: HealthRecords?
    
    init() {
        healthStore = HealthRecords()
    }
    
    func fetchMedicationsForDisease(disease: String) {
        //let request = AF.request("https://swapi.dev/api/films")
        // Get classID for disease (in this case dementia).
        let url1 = "https://rxnav.nlm.nih.gov/REST/rxclass/class/byName.xml?className=\(disease)&classTypes=DISEASE"
        AF.request(url1).responseData { response in
            switch response.result {
            case .success(let value):
                // API returns XML format which can be parsed with SWXMLHash pod.
                let xml = SWXMLHash.parse(value)
                let diseaseCode = xml["rxclassdata"]["rxclassMinConceptList"]["rxclassMinConcept"]["classId"].element!.text
                let url2 = "https://rxnav.nlm.nih.gov/REST/rxclass/classMembers.xml?classId=\(diseaseCode)&relaSource=MEDRT&rela=may_treat&direct=0&term_type=IN,MIN,PIN"
                AF.request(url2).responseData { response in
                    switch response.result {
                    case .success(let value):
                        let xml = SWXMLHash.parse(value)
                        for elem in xml["rxclassdata"]["drugMemberGroup"]["drugMember"].all {
                            print("\(elem["minConcept"]["name"].element!.text): \(elem["minConcept"]["rxcui"].element!.text)")
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}
