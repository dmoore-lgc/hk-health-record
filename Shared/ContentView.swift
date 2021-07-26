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
    @State private var showingMatchAlert = false
    @State var message = ""
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
                        message = healthStore!.compareArrays(uMeds: uMeds, dMeds: dMeds, disease: name)
                        showingMatchAlert = true
                    } label: {
                        Text("Evaluate Medications")
                    }
                }
            }
            .navigationTitle(Text("Health Record"))
            .alert(isPresented: $showingMatchAlert) {
                Alert(title: Text("Health Record Evaluated"), message: Text(message), dismissButton: .default(Text("OK")))
            }
        }.onAppear {
            healthStore!.requestAuthorization { success in
            }
            healthStore?.getUserSamples(identifier: .allergyRecord) { results in
            }
            healthStore?.getUserSamples(identifier: .procedureRecord) { results in
            }
            healthStore?.getUserSamples(identifier: .medicationRecord) { results in
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
    
    func buttonClicked() {
         print("Button Clicked")
    }
}
class Controller: UIViewController {
    @IBAction func showAlertButtonTapped(_ sender: UIButton) {

            // create the alert
            let alert = UIAlertController(title: "My Title", message: "This is my message.", preferredStyle: UIAlertController.Style.alert)

            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

            // show the alert
            self.present(alert, animated: true, completion: nil)
        }
}
