//
//  ObserverQueryViewController.swift
//  LearnHealthKit
//
//  Created by Matheus Oliveira Costa on 28/08/19.
//  Copyright © 2019 mathocosta. All rights reserved.
//

import UIKit
import HealthKit

class ObserverQueryViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Checa se o HealthKit está disponível para o device
        if HKHealthStore.isHealthDataAvailable() {
            let healthStore = HKHealthStore()

            guard let stepCountType = HKObjectType.quantityType(
                forIdentifier: .stepCount) else { return }

            // Solicita autorização ao usuário para compartilhamento e leitura dos dados
            healthStore.requestAuthorization(toShare: [stepCountType], read: [stepCountType]) {
                [weak self] (success, error) in
                guard success == true, error == nil else {
                    fatalError(error!.localizedDescription)
                }

                let query = HKObserverQuery(sampleType: stepCountType, predicate: nil) {
                    (query, completionHandler, error) in
                    guard error == nil else { return }

                    // TODO: Continuar a query para obter os dados
                }

                healthStore.execute(query)
            }
        }
    }

    func updateDailyStepCount(quantity: HKQuantity) {

    }

}
