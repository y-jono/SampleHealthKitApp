//
//  VitalStore.swift
//  SampleHealthKitApp
//
//  Created by Seino Yoshinori on 2016/05/23.
//  Copyright © 2016年 yoshinori. All rights reserved.
//

import Foundation
import HealthKit

class VitalStore {

    // Save
    class func saveHeartRate(heartRateValue: Double) {
        if !HKHealthStore.isHealthDataAvailable() { print("HealthData is NOT available."); return; }
        
        // Save the user's heart rate into HealthKit.
        let heartRateUnit: HKUnit = HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit())
        let heartRateQType : HKQuantityType! = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
        
        // 永続化処理完了時に非同期で呼び出されます。
        saveHealthValueWithUnit(heartRateUnit, type: heartRateQType, value: heartRateValue, completion: {
            success, error in
            
            if error != nil {
                NSLog(error!.description)
                return
            }
            
            if success {
                NSLog("心拍データの永続化に成功しました。")
            }
        })
    }
    
    class func saveBodyTemperature(bodyTemperature: Double) {
        if !HKHealthStore.isHealthDataAvailable() { print("HealthData is NOT available."); return; }
        
        // 体温の単位を生成します。単位は℃（摂氏）です。
        let btUnit: HKUnit! = HKUnit.degreeCelsiusUnit()
        // 体温情報の型を生成します。
        let btType: HKQuantityType! = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyTemperature)
        
        // 永続化処理完了時に非同期で呼び出されます。
        saveHealthValueWithUnit(btUnit, type: btType, value: bodyTemperature, completion: {
            success, error in
            
            if error != nil {
                NSLog(error!.description)
                return
            }
            
            if success {
                NSLog("体温データの永続化に成功しました。")
            }
        })
    }
    
    /**
     引数に渡された文字列を指定のデータへ変換してHealthStoreへ永続化します。
     渡される文字列は、Double型へキャスト出来る形式である必要があります。
     :param: unit       健康情報の単位型
     :param: type       健康情報のデータ型
     :param: value   データ
     :param: completion 永続化処理完了時に実行される処理
     */
    private class func saveHealthValueWithUnit(unit: HKUnit! , type: HKQuantityType!, value: Double, completion: ((success: Bool, error: NSError?) -> Void)) {
        // 保存領域オブジェクトをインスタンス化します。
        let healthStore: HKHealthStore = HKHealthStore()
        
        // 数値オブジェクトを生成します。単位と値が入ります。
        let quantity: HKQuantity = HKQuantity(unit: unit, doubleValue: value)
        
        // HKObjectのサブクラスである、HKQuantitySampleオブジェクトを生成します。
        // 計測の開始時刻と終了時刻が同じ場合は同じ値を設定します。
        let sample: HKQuantitySample = HKQuantitySample(type: type, quantity: quantity, startDate: NSDate(), endDate: NSDate())
        
        // 健康情報のデータ型を保持したNSSetオブジェクトを生成します。
        // 永続化したい情報が複数ある場合はobjectに複数のデータ型配列を設定します。
        let types = Set<HKQuantityType>(arrayLiteral: type);
        
        let authStatus:HKAuthorizationStatus = healthStore.authorizationStatusForType(type)
        
        if authStatus == .SharingAuthorized {
            healthStore.saveObject(sample, withCompletion:completion)
        } else {
            // 体温型のデータをHealthStoreに永続化するために、ユーザーへ許可を求めます。
            // 許可されたデータのみ、アプリケーションからHealthStoreへ書き込みする権限が与えられます。
            // ヘルスケアの[ソース]タブ画面がモーダルで表示されます。
            // 第1引数に指定したNSSet!型のshareTypesの書き込み許可を求めます。
            // 第2引数に指定したNSSet!型のreadTypesの読み込み許可を求めます。
            
            healthStore.requestAuthorizationToShareTypes(types, readTypes: types) {
                success, error in
                
                if error != nil {
                    NSLog(error!.description);
                    return
                }
                
                if success {
                    NSLog("保存可能");
                    healthStore.saveObject(sample, withCompletion:completion)
                }
            }
        }
    }
    
    // Find
    class func findAllBodyTemperature() {
        if !HKHealthStore.isHealthDataAvailable() { print("HealthData is NOT available."); return; }
        
        // 体温の単位を生成します。単位は℃（摂氏）です。
        let btUnit: HKUnit! = HKUnit.degreeCelsiusUnit()
        // 体温情報の型を生成します。
        let btType: HKQuantityType! = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyTemperature)
        
        // 取得処理完了時に非同期で呼び出されます。
        findAllHealthValueWithUnit(btUnit, type: btType , completion: {
            query, responseObj, error in
            
            if error != nil {
                NSLog(error!.description)
                return
            }
            
            // 取得した結果がresponseObjに格納されています。
            // アプリケーションで使用する場合、[AnyObject]!型のresponseObjを必要な型にキャストする必要があります。
            NSLog("resultObj : \(responseObj)")
            
            let btUnit: HKUnit = HKUnit.degreeCelsiusUnit()
            
            var btResults: [Double!] = []
            
            // HealthStoreで使用していた型から体温の値へと復元します。
            for bodyTemperature: HKQuantitySample in responseObj as! [HKQuantitySample] {
                // 値を取得します。
                let btQuantity: HKQuantity! = bodyTemperature.quantity
                let btResult: Double = btQuantity.doubleValueForUnit(btUnit)
                btResults.append(btResult);
            }
            NSLog("values : \(btResults)")
        })
    }
    
    /**
     HealthStoreから引数に渡されたデータ型に一致する健康情報を全件取得します。
     :param: unit       健康情報の単位型
     :param: type       取得したいデータ型
     :param: completion 取得完了時に実行される処理
     */
    private class func findAllHealthValueWithUnit(unit: HKUnit!, type: HKQuantityType!, completion: ((query: HKSampleQuery, responseObj: [HKSample]?, error: NSError?) -> Void)) {
        let healthStore = HKHealthStore()
        
        // HealthStoreのデータを全件取得するHKSampleQueryを返却します。
        let findAllQuery : () -> HKSampleQuery = {
            return HKSampleQuery(sampleType: type, predicate: nil, limit: 0, sortDescriptors: nil, resultsHandler: completion)
        }
        
        let types: Set<HKQuantityType> = Set<HKQuantityType>(arrayLiteral: type)
        
        let authStatus:HKAuthorizationStatus = healthStore.authorizationStatusForType(type)
        
        if authStatus == .SharingAuthorized {
            healthStore.executeQuery(findAllQuery())
        } else {
            // 体温型のデータをHealthStoreから取得するために、ユーザーへ許可を求めます。
            // 許可されたデータのみ、アプリケーションからHealthStoreへ読み込みする権限が与えられます。
            // ヘルスケアの[ソース]タブ画面がモーダルで表示されます。
            // 第1引数に指定したNSSet!型のshareTypesの書き込み許可を求めます。
            // 第2引数に指定したNSSet!型のreadTypesの読み込み許可を求めます。
            
            healthStore.requestAuthorizationToShareTypes(types, readTypes: types) {
                success, error in
                
                if error != nil {
                    NSLog(error!.description);
                    return
                }
                
                if success {
                    NSLog("取得可能");
                    // 引数に指定されたクエリーを実行します
                    healthStore.executeQuery(findAllQuery())
                }
            }
        }
    }
    
    // Observe
    // 監視登録のためにアプリ起動後１度だけ呼べばよさそう。predicate == nil なので全てのデータが取得されてします。
    func observeBodyTemperature() {
        if !HKHealthStore.isHealthDataAvailable() { print("HealthData is NOT available."); return; }
        
        let healthStore: HKHealthStore = HKHealthStore()
        let tempType: HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyTemperature)!
        
        let endDate: NSSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let observerQuery: HKObserverQuery = HKObserverQuery(sampleType: tempType, predicate: nil, updateHandler: {
            (query: HKObserverQuery, completionHandler: HKObserverQueryCompletionHandler, error: NSError?) in
            
            // memo: １観察クエリにつき、１サンプルクエリのインスタンスが必要。複数の観察クエリを発行するとき、その数と同じだけのサンプルクエリが必要。
            let sampleQuery: HKSampleQuery = HKSampleQuery(sampleType: tempType, predicate: nil, limit: 0, sortDescriptors: [endDate], resultsHandler: {
                (query: HKSampleQuery, results: [HKSample]?, error: NSError?) in
                
                let btUnit: HKUnit = HKUnit.degreeCelsiusUnit()
                
                var btResults: [Double!] = []
                
                // HealthStoreで使用していた型から体温の値へと復元します。
                for bodyTemperature: HKQuantitySample in results as! [HKQuantitySample] {
                    // 値を取得します。
                    let btQuantity: HKQuantity! = bodyTemperature.quantity
                    let btResult: Double = btQuantity.doubleValueForUnit(btUnit)
                    btResults.append(btResult);
                }
                NSLog("values : \(btResults)")
            })
            
            // FIXME: healthStore.authorizationStatusForType(type) にてヘルスデータへのアクセス権限がないまま実行するとクラッシュする
            healthStore.executeQuery(sampleQuery)
        })
        
        // FIXME: healthStore.authorizationStatusForType(type) にてヘルスデータへのアクセス権限がないまま実行するとクラッシュする
        healthStore.executeQuery(observerQuery)
    }
    
    // memo: 監視登録のためにアプリ起動後１度だけ呼べばよさそう。差分だけ取得できる。
    func observeAnchoredBodyTemperature() {
        if !HKHealthStore.isHealthDataAvailable() { print("HealthData is NOT available."); return; }
        
        let healthStore: HKHealthStore = HKHealthStore()
        let tempType: HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyTemperature)!
        
        var lastAnchor: HKQueryAnchor = HKQueryAnchor(fromValue: 0)
        
        let observerQuery = HKObserverQuery(sampleType: tempType, predicate: nil, updateHandler: {
            (query: HKObserverQuery, completionHandler: HKObserverQueryCompletionHandler!, error: NSError?) in
            
            let anchoredObjectQuery = HKAnchoredObjectQuery(type: tempType, predicate: nil, anchor: lastAnchor, limit: 0, resultsHandler: {
                (query: HKAnchoredObjectQuery!, results: [HKSample]?, deletedObjects: [HKDeletedObject]?, newAnchor: HKQueryAnchor?, error: NSError?) in
                NSLog("lastAnchor: \(lastAnchor), newAnchor: \(newAnchor), results.count: \(results!.count)")
                lastAnchor = newAnchor!
                
                let btUnit: HKUnit = HKUnit.degreeCelsiusUnit()
                
                var btResults: [Double!] = []
                
                // HealthStoreで使用していた型から体温の値へと復元します。
                for bodyTemperature: HKQuantitySample in results as! [HKQuantitySample] {
                    // 値を取得します。
                    let btQuantity: HKQuantity! = bodyTemperature.quantity
                    let btResult: Double = btQuantity.doubleValueForUnit(btUnit)
                    btResults.append(btResult);
                }
                NSLog("values : \(btResults)")
            })
            
            // FIXME: healthStore.authorizationStatusForType(type) にてヘルスデータへのアクセス権限がないまま実行するとクラッシュする
            healthStore.executeQuery(anchoredObjectQuery)
        })
        
        // FIXME: healthStore.authorizationStatusForType(type) にてヘルスデータへのアクセス権限がないまま実行するとクラッシュする
        healthStore.executeQuery(observerQuery)
    }
    
    
}
