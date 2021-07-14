//
//  ContentView.swift
//  Shared
//
//  Created by David Moore on 30/06/2021.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    var body: some View {
        Button {
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
}
