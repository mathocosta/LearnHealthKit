//
//  ViewController.swift
//  LearnHealthKit
//
//  Created by Matheus Oliveira Costa on 26/08/19.
//  Copyright © 2019 mathocosta. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Checa se o HealthKit está disponível para o device
        if HKHealthStore.isHealthDataAvailable() {
            let healthStore = HKHealthStore()

            guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount),
                let distanceWalkingRunningType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
                let activeEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
                let basalEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) else {
                    return
            }

            // Tipos dos dados escolhidos para serem lidos e utilizados
            let allTypes = Set([
                stepCountType,
                distanceWalkingRunningType,
                activeEnergyBurnedType,
                basalEnergyBurnedType
            ])

            // Solicita autorização ao usuário para compartilhamento e leitura dos dados
            healthStore.requestAuthorization(toShare: allTypes, read: allTypes) {
                [weak self] (success, error) in
                guard success == true, error == nil else {
                    fatalError(error!.localizedDescription)
                }

                // Executa uma query para buscar os samples relacionados a contagem
                // de passos em na store do usuário
                self?.runSampleQuery(for: activeEnergyBurnedType, in: healthStore)

                // Executa uma query para buscar os samples relacionados a contagem de passos,
                // mas imprime somente o somatório da contagem dos passos do dia
                self?.runStatisticsQuery(for: distanceWalkingRunningType, in: healthStore)
            }
        }

    }


    /// O método cria e executa uma query para buscar os samples de um tipo passado como parâmetro
    /// na chamada do método. Também é preciso passar uma HKHealthStore para ser utilizada.
    ///
    /// - Parameters:
    ///   - sampleType: Tipo dos samples que devem ser obtidos
    ///   - store: Instância de HKHealthStore para executar a consulta
    func runSampleQuery(for sampleType: HKSampleType, in store: HKHealthStore) {
        // Constrói uma HKSampleQuery que retorna HKSamples com os dados do
        // tipo do `sampleType`. Os resultados podem ser filtrados por meio de um `predicate`
        // e ordenados pelos `sortDescriptors`.
        let sampleQuery = HKSampleQuery(
            sampleType: sampleType,
            predicate: nil,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { (query, samples, error) in
            // Os samples retornados são do tipo HKSample. No entanto, é melhor converter para
            // um tipo de sample específico para conseguir os dados recebidos
            guard let actualSamples = samples,
                let quantitySamples = actualSamples as? [HKQuantitySample] else {
                    return
            }

            for sample in quantitySamples {
                print("\(sample.startDate) - \(sample.endDate): \(sample.quantity)")
            }
        }

        // Executa a query na store
        store.execute(sampleQuery)
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
                let unit = HKUnit.meter()
                totalSteps = quantity.doubleValue(for: unit)
            }

            print(totalSteps)
        }

        // Executa a query na store
        store.execute(statisticsQuery)
    }

}

