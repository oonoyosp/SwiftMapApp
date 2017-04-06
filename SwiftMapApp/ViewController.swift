//
//  ViewController.swift
//  SwiftMapApp
//
//  Created by Natsumo Ikeda on 2016/08/10.
//  Copyright © 2016年 NIFTY Corporation. All rights reserved.
//

import UIKit
import NCMB
import GoogleMaps
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    // Google Map
    @IBOutlet weak var mapView: GMSMapView!
    // TextField
    @IBOutlet weak var latTextField: UITextField!
    @IBOutlet weak var lonTextField: UITextField!
    // Label
    @IBOutlet weak var label: UILabel!
    // 現在地
    var myLocation: CLLocation!
    var locationManager: CLLocationManager!
    
    // 新宿駅の情報
    let SHINJUKU = (title:"新宿駅",
                    snippet:"Shinjuku Station",
                    location:NCMBGeoPoint(latitude: 35.690549, longitude: 139.699550), // 位置情報
                    color:UIColor.greenColor()
    )
    // ニフティの情報
    let NIFTY = (title:"ニフティ株式会社",
                 snippet:"NIFTY Corporation",
                 location:NCMBGeoPoint(latitude: 35.696144, longitude: 139.689485), // 位置情報
                 imageName:"mBaaS.png"
    )
    // 西新宿駅の位置情報
    let WEST_SHINJUKU_LOCATION = NCMBGeoPoint(latitude: 35.6945080, longitude: 139.692692)
    // ズームレベル
    let ZOOM: Float = 14.5
    // 検索範囲
    let SEAECH_RANGE = ["全件検索", "現在地から半径5km以内を検索", "現在地から半径1km以内を検索", "新宿駅と西新宿駅の間を検索"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 位置情報取得開始
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
        }
        
        // 起動時は新宿駅に設定
        showMap(SHINJUKU.location)
        addColorMarker(SHINJUKU.location, title: SHINJUKU.title, snippet: SHINJUKU.snippet, color: SHINJUKU.color)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // 位置情報取得の停止
        if CLLocationManager.locationServicesEnabled() {
            locationManager.stopUpdatingLocation()
        }
    }
    
    // 位置情報許可状況確認メソッド
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            // 初回のみ許可要求
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            // 位置情報許可を依頼するアラートの表示
            alertLocationServiceDisabled()
        case .authorizedAlways, .authorizedWhenInUse:
            break
        }
    }
    
    // 位置情報許可依頼アラート
    func alertLocationServiceDisabled() {
        let alert = UIAlertController(title: "位置情報が許可されていません", message: "位置情報サービスを有効にしてください", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "設定", style: .default, handler: { (action: UIAlertAction) -> Void in
            let url = URL(string: UIApplicationOpenSettingsURLString)!
            UIApplication.shared.openURL(url)
        }))
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: { (action: UIAlertAction) -> Void in
        }))
        present(alert, animated: true, completion: nil)
    }
    
    // 位置情報が更新されるたびに呼ばれるメソッド
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 値をローカルに保存
        myLocation = locations[0]
        // TextFieldに表示
        self.latTextField.text = String(format:"%.6f", self.myLocation.coordinate.latitude)
        self.lonTextField.text = String(format:"%.6f", self.myLocation.coordinate.longitude)
        self.label.text = "右上の「保存」をタップしてmBaaSに保存しよう！"
    }
    
    // 「保存」ボタン押下時の処理
    @IBAction func saveLocation(_ sender: UIButton) {
        // チェック
        if myLocation == nil {
            print("位置情報が取得できていません")
            label.text = "位置情報が取得できていません"
        } else {
            print("位置情報が取得できました")
            label.text = "位置情報が取得できました"
            
            // アラートを表示
            let alert = UIAlertController(title: "現在地を保存します", message: "情報を入力してください", preferredStyle: .alert)
            // UIAlertControllerにtextFieldを2つ追加
            alert.addTextField { (textField: UITextField!) -> Void in
                textField.placeholder = "タイトル"
            }
            alert.addTextField { (textField: UITextField!) -> Void in
                textField.placeholder = "コメント"
            }
            // アラートの保存押下時の処理
            alert.addAction(UIAlertAction(title: "保存", style: .default) { (action: UIAlertAction!) -> Void in
                // 入力値の取得
                let title = alert.textFields![0].text
                let snippet = alert.textFields![1].text
                let lat = String(format:"%.6f", self.myLocation.coordinate.latitude)
                let lon = String(format:"%.6f", self.myLocation.coordinate.longitude)
                
                /** 【mBaaS：データストア】位置情報の保存 **/
                 // NCMBGeoPointの生成
                let geoPoint = NCMBGeoPoint(latitude: atof(lat), longitude: atof(lon))
                // NCMBObjectを生成
                let object = NCMBObject(className: "GeoPoint")
                // 値を設定
                object.setObject(geoPoint, forKey: "geolocation")
                object.setObject(title, forKey: "title")
                object.setObject(snippet, forKey: "snippet")
                // 保存の実施
                object.saveInBackgroundWithBlock { (error: NSError!) -> Void in
                    if error != nil {
                        // 位置情報保存失敗時の処理
                        print("位置情報の保存に失敗しました：\(error.code)")
                        self.label.text = "位置情報の保存に失敗しました：\(error.code)"
                    } else {
                        // 位置情報保存成功時の処理
                        print("位置情報の保存に成功しました：[\(geoPoint.latitude), \(geoPoint.longitude)]")
                        self.label.text = "位置情報の保存に成功しました：[\(geoPoint.latitude), \(geoPoint.longitude)]"
                        // マーカーを設置
                        self.addColorMarker(geoPoint, title: object.objectForKey("title") as! String, snippet: object.objectForKey("snippet") as! String, color: UIColor.blueColor())
                    }
                }
            })
            // アラートのキャンセル押下時の処理
            alert.addAction(UIAlertAction(title: "キャンセル", style: .default) { (action: UIAlertAction!) -> Void in
                self.label.text = "保存がキャンセルされました"
                print("保存がキャンセルされました")
            })
            present(alert, animated: true, completion: nil)
        }
    }
    
    // 「保存した場所を見る」ボタン押下時の処理
    @IBAction func getLocationData(_ sender: UIBarButtonItem) {
        // Action Sheet
        let actionSheet = UIAlertController(title: "保存した場所を地図に表示します", message: "検索範囲を選択してください", preferredStyle: .actionSheet)
        // iPadの場合
        if UIDevice.current.userInterfaceIdiom == .pad {
            print("iPad使用")
            actionSheet.popoverPresentationController!.sourceView = self.view;
            actionSheet.popoverPresentationController!.sourceRect = CGRect(x: self.view.bounds.size.width*0.5, y: self.view.bounds.size.height*0.9, width: 1.0, height: 1.0);
            actionSheet.popoverPresentationController!.permittedArrowDirections = UIPopoverArrowDirection.down
        }
        
        // キャンセル
        actionSheet.addAction(UIAlertAction(title: "キャンセル", style: .cancel) { (action: UIAlertAction!) -> Void in
            })
        // 検索条件を設定
        for i in 0..<SEAECH_RANGE.count {
            actionSheet.addAction(UIAlertAction(title: SEAECH_RANGE[i], style: .default) { (action: UIAlertAction!) -> Void in
                self.getLocaion(action.title!)
                })
        }
        // アラートを表示する
        present(actionSheet, animated: true, completion: nil)
    }
    
    /** 【mBaaS：データストア(位置情報)】保存データの取得 **/
    func getLocaion(_ title: String) {
        // チェック
        if myLocation == nil {
            return
        }
        
        // 現在地
        let geoPoint = NCMBGeoPoint(latitude: myLocation.coordinate.latitude, longitude: myLocation.coordinate.longitude)
        // それぞれのクラスの検索クエリを作成
        let queryGeoPoint = NCMBQuery(className: "GeoPoint")
        let queryShop = NCMBQuery(className: "Shop")
        // 検索条件を設定
        switch title {
        case SEAECH_RANGE[0]:
            print(SEAECH_RANGE[0])
            break
        case SEAECH_RANGE[1]:
            print(SEAECH_RANGE[1])
            // 半径5km以内(円形検索)
            queryGeoPoint.whereKey("geolocation", nearGeoPoint: geoPoint, withinKilometers: 5.0)
            queryShop.whereKey("geolocation", nearGeoPoint: geoPoint, withinKilometers: 5.0)
        case SEAECH_RANGE[2]:
            print(SEAECH_RANGE[2])
            // 半径1km以内(円形検索)
            queryGeoPoint.whereKey("geolocation", nearGeoPoint: geoPoint, withinKilometers: 1.0)
            queryShop.whereKey("geolocation", nearGeoPoint: geoPoint, withinKilometers: 1.0)
        case SEAECH_RANGE[3]:
            print(SEAECH_RANGE[3])
            // 新宿駅と西新宿駅の間(矩形検索)
            queryGeoPoint.whereKey("geolocation", withinGeoBoxFromSouthwest: SHINJUKU.location, toNortheast: WEST_SHINJUKU_LOCATION)
            queryShop.whereKey("geolocation", withinGeoBoxFromSouthwest: SHINJUKU.location, toNortheast: WEST_SHINJUKU_LOCATION)
        default:
            print("\(SEAECH_RANGE[0])(エラー)")
            break
        }
        // データストアを検索
        queryGeoPoint.findObjectsInBackgroundWithBlock({ (objects: Array!, error: NSError!) -> Void in
            if error != nil {
                // 検索失敗時の処理
                print("GeoPointクラスの検索に失敗しました:\(error.code)")
                self.label.text = "GeoPointクラスの検索に失敗しました:\(error.code)"
            } else {
                // 検索成功時の処理
                print("GeoPointクラスの検索に成功しました")
                self.label.text = "GeoPointクラスの検索に成功しました"
                for object in objects {
                    self.addColorMarker(object.objectForKey("geolocation") as! NCMBGeoPoint, title: object.objectForKey("title") as! String, snippet: object.objectForKey("snippet") as! String, color: UIColor.blueColor())
                }
            }
        })
        queryShop.findObjectsInBackgroundWithBlock({ (objects: Array!, error: NSError!) -> Void in
            if error != nil {
                // 検索失敗時の処理
                print("Shopクラスの検索に失敗しました:\(error.code)")
                self.label.text = "Shopクラスの検索に失敗しました:\(error.code)"
            } else {
                // 検索成功時の処理
                print("Shopクラスの検索に成功しました")
                self.label.text = "Shopクラスの検索に成功しました"
                for object in objects {
                    self.addImageMarker(object.objectForKey("geolocation") as! NCMBGeoPoint, title: object.objectForKey("shopName") as! String, snippet: object.objectForKey("category") as! String, imageName: object.objectForKey("image") as! String)
                }
            }
        })
    }
    
    // 「お店（スプーンとフォーク）」ボタン押下時の処理
    @IBAction func showShops(_ sender: UIBarButtonItem) {
        // Shopデータの取得
        getShopDataWithBlock({ (objects: Array!, error: NSError!) -> Void in
            if error != nil {
                // 検索失敗時の処理
                print("Shop情報の取得に失敗しました:\(error.code)")
                self.label.text = "Shop情報の取得に失敗しました"
            } else {
                // 検索成功時の処理
                print("Shop情報の取得に成功しました")
                self.label.text = "Shop情報の取得に成功しました"
                // マーカーを設定
                for shop in objects {
                    self.addImageMarker(shop.objectForKey("geolocation") as! NCMBGeoPoint, title: shop.objectForKey("shopName") as! String, snippet: shop.objectForKey("category") as! String, imageName: shop.objectForKey("image") as! String)
                }
            }
        })
    }
    
    /** 【mBaaS：データストア】「Shop」クラスのデータを取得 **/
    func getShopDataWithBlock(_ block: NCMBArrayResultBlock!) {
        // 「Shop」クラスの検索クエリを作成
        let query = NCMBQuery(className: "Shop")
        // データストアを検索
        query.findObjectsInBackgroundWithBlock({ (objects: Array!, error: NSError!) -> Void in
            block(objects,error)
        })
    }
    
    // 「nifty」ボタン押下時の処理
    @IBAction func showNifty(_ sender: UIBarButtonItem) {
        // マーカーを設定
        addImageMarker(NIFTY.location, title: NIFTY.title, snippet: NIFTY.snippet, imageName: NIFTY.imageName)
    }
    
    // 地図を表示
    func showMap (_ location: NCMBGeoPoint) {
        // cameraの作成と設定
        let camera = GMSCameraPosition.cameraWithLatitude(location.latitude, longitude: location.longitude, zoom: ZOOM)
        mapView.camera = camera
        // 現在地の有効化
        mapView.myLocationEnabled = true
        // 現在地を示す青い点を表示
        mapView.settings.myLocationButton = true
    }
    
    // マーカー作成
    func addMarker(_ location: NCMBGeoPoint, title: String, snippet: String, color: UIColor?, imageName: String?) {
        let marker = GMSMarker()
        // 位置情報
        marker.position = CLLocationCoordinate2DMake(location.latitude, location.longitude)
        // タイトル
        marker.title = title
        // コメント
        marker.snippet = snippet
        // アイコン
        if let unwrappedImageName = imageName {
            /** 【mBaaS：ファイルストア】アイコン画像データを取得 **/
            // ファイル名を設定
            let imageFile = NCMBFile.fileWithName(unwrappedImageName, data: nil)
            // ファイルを検索
            imageFile.getDataInBackgroundWithBlock{ (data: Data!, error: NSError!) -> Void in
                if error != nil {
                    // ファイル取得失敗時の処理
                    print("\(snippet)icon画像の取得に失敗しました:\(error.code)")
                } else {
                    // ファイル取得成功時の処理
                    print("\(snippet)icon画像の取得に成功しました")
                    // 画像アイコン
                    marker.icon = UIImage.init(data: data)
                }
                // マーカー表示時のアニメーションを設定
                marker.appearAnimation = kGMSMarkerAnimationPop
                // マーカーを表示するマップの設定
                marker.map = self.mapView
            }
        } else if let unwrappedColor = color {
            // アイコン
            marker.icon = GMSMarker.markerImageWithColor(unwrappedColor)
            // マーカー表示時のアニメーションを設定
            marker.appearAnimation = kGMSMarkerAnimationPop
            // マーカーを表示するマップの設定
            marker.map = mapView
        }
    }
    // マーカー作成 (カラーアイコン)
    func addColorMarker(_ location: NCMBGeoPoint, title: String, snippet: String, color: UIColor) {
        addMarker(location, title: title, snippet: snippet, color: color, imageName: nil)
    }
    // マーカー作成（画像アイコン）
    func addImageMarker(_ location: NCMBGeoPoint, title: String, snippet: String, imageName: String) {
        addMarker(location, title: title, snippet: snippet, color: nil, imageName: imageName)
    }
    
    // 「ゴミ箱」ボタン押下時の処理
    @IBAction func clearMarker(_ sender: UIBarButtonItem) {
        // マーカーを全てクリアする
        mapView.clear()
    }
}

