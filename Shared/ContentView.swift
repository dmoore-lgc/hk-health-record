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
    @State private var name: String = ""
    @State var medications = [String]()
    @State var dMeds = [String]()
    @State var uMeds = [String]()
    private var healthStore: HealthRecords?
    
    init() {
        healthStore = HealthRecords()
        healthStore!.requestAuthorization { success in
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Asthma
                // Rhinitis
                // Goiter
                Section(header: Text("USER INPUT")) {
                    TextField("Disease/Condition e.g. Rhinitis", text: $name)
                }
                Section {
                    Button {
                        print(String(name.unicodeScalars.filter(CharacterSet.alphanumerics.contains)))
                        healthStore?.fetchMedicationsForDisease(disease: String(name.unicodeScalars.filter(CharacterSet.alphanumerics.contains)), completionHandler: { results in
                            print("Disease medication RXCUIs are: \(results!)")
                            dMeds = results!
                        })
                    } label: {
                        Text("Enter Disease")
                    }
                    Button {
                        healthStore!.compareArrays(uMeds: uMeds, dMeds: dMeds, disease: name)
                    } label: {
                        Text("Evaluate Medications")
                    }
                }
            }
            .navigationTitle(Text("Health Record"))
        }.onAppear {
            healthStore?.getUserMeds { results in
                uMeds = results
            }
        }
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                ContentView()
            }
        }
    }
}
