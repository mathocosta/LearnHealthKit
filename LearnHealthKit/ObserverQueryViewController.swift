//
//  ObserverQueryViewController.swift
//  LearnHealthKit
//
//  Created by Matheus Oliveira Costa on 28/08/19.
//  Copyright © 2019 mathocosta. All rights reserved.
//

import UIKit
import HealthKit

final class ObserverQueryViewController: UIViewController {

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

                // Adiciona o observer para a contagem de passos
                self?.observer(for: stepCountType, in: healthStore)
            }
        }
    }


    /// Método que cria uma `HKObserverQuery` para ficar esperando modificações nos
    /// dados do `HKSampleType` passado como argumento.
    ///
    /// - Parameters:
    ///   - type: Tipo do sample para ser observado
    ///   - store: Instância de `HKHealthStore` para executar a consulta
    func observer(for type: HKSampleType, in store: HKHealthStore) {
        let query = HKObserverQuery(sampleType: type, predicate: nil) {
            [weak self] (query, completionHandler, error) in
            guard let quantityType = type as? HKQuantityType,
                error == nil else { return }

            self?.runStatisticsQuery(for: quantityType, in: store)
        }

        store.execute(query)
    }

    /// O método cria e executa uma query para buscar os samples do tipo passado como parâmetro e
    /// que são do dia atual. Depois calcula o somatório para imprimir no console. É preciso passar
    /// uma HKHealthStore para ser utilizada.
    ///
    /// - Parameters:
    ///   - sampleType: Tipo dos samples que devem ser obtidos
    ///   - store: Instância de HKHealthStore para executar a consulta
    func runStatisticsQuery(for sampleType: HKQuantityType, in store: HKHealthStore) {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)

        let startDate = calendar.date(from: components)!
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)

        // Define um predicate para os samples que serão retornados. No caso, os que fazem parte
        // do intervalo de tempo entre o startDate e endDate
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate, end: endDate, options: .strictStartDate)

        // Constrói uma HKStatisticsQuery que busca os samples do tipo definido no `quantityType`,
        // filtra baseado no predicate e executa a operação definida nas `options`
        let statisticsQuery = HKStatisticsQuery(
            quantityType: sampleType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { (query, result, error) in
            guard let result = result else { return }

            var totalSteps = 0.0

            if let quantity = result.sumQuantity() {
                let unit = HKUnit.count()
                totalSteps = quantity.doubleValue(for: unit)
            }

            print(totalSteps)
        }

        // Executa a query na store
        store.execute(statisticsQuery)
    }

}
