//
//  DbMemory.swift
//  ch09-leejaemoon-tableView
//
//  Created by jmlee on 2023/04/26.
//

import Foundation

class DbMemory: Database {
 
    private var storage: [Plan]  // 데이터 저장고

    // storgae내의 데이터변화가 있으면 이 함수를 호출해야 함
    var parentNotification: ((Plan?, DbAction?) -> Void)?

    // required라는 것은 이 클래스가 Database를 만족하여야 하기 때문임, see Database
    required init(parentNotification: ((Plan?, DbAction?) -> Void)?) {

        self.parentNotification = parentNotification // nil일 수도 있다

        storage = []
        // 100개의 가상 데이터를 만든다. 현재 기준으로 -50일 +50일 사이에 랜덤하게 만듬
        let amount = 10
        for _ in 0..<amount{
            let delta = Int(arc4random_uniform(UInt32(amount))) - amount/2
            let date = Date(timeInterval: TimeInterval(delta*24*60*60), since: Date())
            storage.append(Plan(date: date, withData: true))
        }
    }
}
extension DbMemory{    // DbMemory.swift
    // 이 함수는 fromDate~toDate사이의 플랜을 찾아서 리턴한다.
    // 재미있는 것은 찾아서 전부 한거번에 리턴하는 것이 아니라
    // parentNotification에게 한번에 1개씩 전해준다
    func queryPlan(fromDate: Date, toDate: Date) {
        
        for i in 0..<storage.count{
            if storage[i].date >= fromDate && storage[i].date <= toDate{
                if let parentNotification = parentNotification{
        parentNotification(storage[i], .Add) // 한개씩 여러번 전달한다
                }
            }
        }
    }
}
extension DbMemory{// DbMemory.swift
    // 주어진 플랜에 대하여 삽입, 수정, 삭제를 storage에서 하고
    // 역시 parentListener를 호출하여 이러한 사실을 알린다.
    func saveChange(plan: Plan, action: DbAction){
        if action == .Add{
            storage.append(plan)
        }else{
            for i in 0..<storage.count{
                if plan.key == storage[i].key{
                    if action == .Delete{ storage.remove(at: i) }
                    if action == .Modify{ storage[i] = plan }
                    break
                }
            }
        }
        if let parentNotification = parentNotification{
            parentNotification(plan, action)  // 변경된 내역을 알려준다
        }
    }
}
