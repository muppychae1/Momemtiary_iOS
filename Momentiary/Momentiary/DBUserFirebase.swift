//
//  DBUserFirebase.swift
//  Momentiary
//
//  Created by 0000 on 2023/06/19.
//

import Foundation
import FirebaseFirestore
import FirebaseCore
import FirebaseStorage

class DbUserFirebase {
    
    var reference: CollectionReference

    required init() {
        reference = Firestore.firestore().collection("users")
    }
    
}

extension DbUserFirebase{
    
    func queryPlan(fromDate: Date, toDate: Date) {
        
        if let existQuery = existQuery{    // 이미 적용 쿼리가 있으면 제거, 중복 방지
            existQuery.remove()
        }
        // where plan.date >= fromDate and plan.date <= toDate
        let queryReference = reference.whereField("date", isGreaterThanOrEqualTo: fromDate).whereField("date", isLessThanOrEqualTo: toDate)

        // onChangingData는 쿼리를 만족하는 데이터가 있거나 firestore내에서 다른 앱에 의하여
        // 데이터가 변경되어 쿼리를 만족하는 데이터가 발생하면 호출해 달라는 것이다.
        existQuery = queryReference.addSnapshotListener(onChangingData)
    }
}


extension DbUserFirebase{
    
    func saveChange(plan: Plan, action: DbAction){
        if action == .Delete{
            reference.document(plan.key).delete()    // key로된 plan을 지운다
            return
        }
        // plan을 아카이빙한다.
//        let data = try? NSKeyedArchiver.archivedData(withRootObject: plan, requiringSecureCoding: false)
        
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmssSSS"
        let fileName = dateFormatter.string(from: currentDate)
        let storageRef = Storage.storage().reference().child("images").child("\(fileName).jpg")
        
        if(plan.imageData != nil) {
            // 이미지 데이터를 Storage에 업로드
            storageRef.putData(plan.imageData!, metadata: nil) { (metadata, error) in
                if let error = error {
                    // 업로드 실패
                    print("Failed to upload image to Firebase Storage:", error)
                    return
                }
                
                // 업로드된 이미지의 다운로드 URL을 받아옴
                storageRef.downloadURL { (url, error) in
                    if let error = error {
                        // 다운로드 URL 가져오기 실패
                        print("Failed to get download URL:", error)
                        return
                    }
                    
                    // 다운로드 URL을 Firestore에 저장
                    if let downloadURL = url?.absoluteString {
                        // Firestore에 데이터 저장
    //                    self.saveImageURLToFirestore(downloadURL: downloadURL)
                        print("다운로드 URL : \(downloadURL)")
                        plan.imageURL = downloadURL
                        let data = plan.toDict()
                        
                        print("데이터 : \(data)")
                        
                        // 저장 형태로 만든다
                        let storeDate: [String : Any] = ["date": plan.date, "data": data]
                        self.reference.document(plan.key).setData(storeDate)
                    }
                }
            }
        } else {
            let data = plan.toDict()
            
            print("데이터 : \(data)")
            
            // 저장 형태로 만든다
            let storeDate: [String : Any] = ["date": plan.date, "data": data]
            reference.document(plan.key).setData(storeDate)
        }
    }
}

extension DbUserFirebase{
    func onChangingData(querySnapshot: QuerySnapshot?, error: Error?){
        guard let querySnapshot = querySnapshot else{ return }
        // 초기 데이터가 하나도 없는 경우에 count가 0이다
        if(querySnapshot.documentChanges.count <= 0){
            if let parentNotification = parentNotification {
                parentNotification(nil, nil)
            } // 부모에게 알림
        }
        // 쿼리를 만족하는 데이터가 많은 경우 한꺼번에 여러 데이터가 온다
        for documentChange in querySnapshot.documentChanges {
            let data = documentChange.document.data() //["date": date, "data": data!]로 구성되어 있다
            // [“data”: data]에서 data는 아카이빙되어 있으므로 언아카이빙이 필요
//            let plan = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data["data"] as! Data) as? Plan
            let plan2 = Plan()
            plan2.toPlan(dict: data["data"] as! [String: Any?])
            var action: DbAction?
            switch(documentChange.type){    // 단순히 DbAction으로 설정
                case    .added: action = .Add
                case    .modified: action = .Modify
                case    .removed: action = .Delete
            }
            if let parentNotification = parentNotification {parentNotification(plan2, action!)} // 부모에게 알림
        }
    }
}

