//
//  ViewController.swift
//  ch09-leejaemoon-tableView
//
//  Created by jmlee on 2023/04/26.
//

import UIKit
import FSCalendar

class PlanGroupViewController: UIViewController {
    @IBOutlet weak var fsCalendar: FSCalendar!
    
    @IBOutlet weak var planGroupTableView: UITableView!
    var planGroup: PlanGroup!
    var selectedDate: Date? = Date()     // 나중에 필요하다
    
    var nickname: String = ""
    var defaultImage: UIImage = UIImage(named: "noPhoto.png")!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Owner.loadOwner(sender: self)
        planGroupTableView.dataSource = self        // 테이블뷰의 데이터 소스로 등록
        planGroupTableView.delegate = self
        fsCalendar.dataSource = self                // 칼렌다의 데이터소스로 등록
        fsCalendar.delegate = self                  // 칼렌다의 딜리게이트로 등록

        fsCalendar.scope = .week
        
        fsCalendar.backgroundColor = #colorLiteral(red: 0.5411764706, green: 0.8078431373, blue: 1, alpha: 1)
        fsCalendar.appearance.selectionColor = #colorLiteral(red: 1, green: 0.6431372549, blue: 0.8980392157, alpha: 1)
        fsCalendar.appearance.todayColor = #colorLiteral(red: 0.6431372549, green: 0.6549019608, blue: 1, alpha: 1)
        
        fsCalendar.appearance.headerTitleColor = UIColor.white
        fsCalendar.appearance.subtitleSelectionColor = .white
        
        // 달력의 평일 날짜 색깔
        fsCalendar.appearance.titleDefaultColor = .white
        // 달력의 토,일 날짜 색깔
        fsCalendar.appearance.titleWeekendColor = .white
        // 달력의 맨 위의 년도, 월의 색깔
        fsCalendar.appearance.headerTitleColor = .white
        // 달력의 요일 글자 색깔
        fsCalendar.appearance.weekdayTextColor = .white
                
        
        // 단순히 planGroup객체만 생성한다
        planGroup = PlanGroup(parentNotification: receivingNotification)
        planGroup.queryData(date: Date())       // 이달의 데이터를 가져온다. 데이터가 오면 planGroupListener가 호출된다.
        //planGroupTableView.isEditing = true
        let leftBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editingPlans1))
        navigationItem.leftBarButtonItem = leftBarButtonItem
        navigationItem.title = nickname
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: #colorLiteral(red: 0.3843137255, green: 0.4078431373, blue: 1, alpha: 1)]

    }
    
    override func viewDidAppear(_ animated: Bool) {
        // 여기서 호출하는 이유는 present라는 함수 ViewController의 함수인데 이함수는 ViewController의 Layout이 완료된 이후에만 동작하기 때문
        Owner.owner = nickname
        Owner.loadOwner(sender: self)
    }
    
    func receivingNotification(plan: Plan?, action: DbAction?){
        // 데이터가 올때마다 이 함수가 호출되는데 맨 처음에는 기본적으로 add라는 액션으로 데이터가 온다.
        self.planGroupTableView.reloadData()  // 속도를 증가시키기 위해 action에 따라 개별적 코딩도 가능하다.
        fsCalendar.reloadData()     // 뱃지의 내용을 업데이트 한다

    }
    
    @IBAction func editingPlans(_ sender: UIButton) {
        if planGroupTableView.isEditing == true{
            planGroupTableView.isEditing = false
            sender.setTitle("Edit", for: .normal)
        }else{
            planGroupTableView.isEditing = true
            sender.setTitle("Done", for: .normal)
        }
    }
    
    @IBAction func addingPlan(_ sender: UIButton) {
//        let plan = Plan(date: nil, withData: true)        // 가짜 데이터 생성
//        planGroup.saveChange(plan: plan, action: .Add)    // 단지 데이터베이스에 저장만한다. 그러면 receivingNotification 함수가 호출되고 tableView.reloadData()를 호출하여 생성된 데이터가 테이블뷰에 보이게 된다.
        performSegue(withIdentifier: "AddPlan", sender: self)
    }
}
extension PlanGroupViewController{
    @IBAction func editingPlans1(_ sender: UIBarButtonItem) {
        if planGroupTableView.isEditing == true{
            planGroupTableView.isEditing = false
            //sender.setTitle("Edit", for: .normal)
            sender.title = "Edit"
        }else{
            planGroupTableView.isEditing = true
            //sender.setTitle("Done", for: .normal)
            sender.title = "Done"
        }
    }
    @IBAction func addingPlan1(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "AddPlan", sender: self)
    }

}

extension PlanGroupViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let planGroup = planGroup{
            return planGroup.getPlans(date:selectedDate).count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlanTableViewCell")!

        // planGroup는 대략 1개월의 플랜을 가지고 있다.
        let plan = planGroup.getPlans(date:selectedDate)[indexPath.row] // Date를 주지않으면 전체 plan을 가지고 온다

        // plan content 띄우기
        (cell.contentView.subviews[2] as! UILabel).text = plan.content
        
        // 이미지 띄우기
        if (plan.imageURL == "") {
            (cell.contentView.subviews[1] as! UIImageView).image = defaultImage
        } else {
            let url = URL(string: plan.imageURL!)
            DispatchQueue.global().async { [weak self] in
                if let data = try? Data(contentsOf: url!) {
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            (cell.contentView.subviews[1] as! UIImageView).image = image
                        }
                    }
                }
            }
        }
        
        // date 띄우기
        (cell.contentView.subviews[0] as! UILabel).text = plan.date.toStringDateTime()

        return cell
    }
}

extension PlanGroupViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        // 삭제할 때
        if editingStyle == .delete{
            
            let plan = self.planGroup.getPlans(date:selectedDate)[indexPath.row]
            let title = "Delete \(plan.content)"
            let message = "Are you sure you want to delete this item?"

            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (action:UIAlertAction) -> Void in
                
                // 선택된 row의 플랜을 가져온다
                let plan = self.planGroup.getPlans(date:self.selectedDate)[indexPath.row]
                // 단순히 데이터베이스에 지우기만 하면된다. 그러면 꺼꾸로 데이터베이스에서 지워졌음을 알려준다
                self.planGroup.saveChange(plan: plan, action: .Delete)
            })
            
            alertController.addAction(cancelAction)
            alertController.addAction(deleteAction)
            present(alertController, animated: true, completion: nil) //여기서 waiting 하지 않는다
        }

    }
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        // 이것은 데이터베이스에 까지 영향을 미치지 않는다. 그래서 planGroup에서만 위치 변경
        let from = planGroup.getPlans(date:selectedDate)[sourceIndexPath.row]
        let to = planGroup.getPlans(date:selectedDate)[destinationIndexPath.row]
        planGroup.changePlan(from: from, to: to)
        tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
    }

}


extension PlanGroupViewController{
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ShowPlan"{
            let planDetailViewController = segue.destination as! PlanDetailViewController
            // plan이 수정되면 이 saveChangeDelegate를 호출한다
            planDetailViewController.saveChangeDelegate = saveChange
            
            // 선택된 row가 있어야 한다
            if let row = planGroupTableView.indexPathForSelectedRow?.row{
                // plan을 복제하여 전달한다. 왜냐하면 수정후 취소를 할 수 있으므로
                planDetailViewController.plan = planGroup.getPlans(date:selectedDate)[row].clone()
            }
        }
        if segue.identifier == "AddPlan"{
            let planDetailViewController = segue.destination as! PlanDetailViewController
            planDetailViewController.saveChangeDelegate = saveChange
            
            // 빈 plan을 생성하여 전달한다
            planDetailViewController.plan = Plan(date:selectedDate, withData: false)
            planGroupTableView.selectRow(at: nil, animated: true, scrollPosition: .none)

        }
    }

    
    // prepare함수에서 PlanDetailViewController에게 전달한다
    func saveChange(plan: Plan){

        // 만약 현재 planGroupTableView에서 선택된 row가 있다면,
        // 즉, planGroupTableView의 row를 클릭하여 PlanDetailViewController로 전이 한다면
        if planGroupTableView.indexPathForSelectedRow != nil{
            planGroup.saveChange(plan: plan, action: .Modify)
        }else{
            // 이경우는 나중에 사용할 것이다.
            planGroup.saveChange(plan: plan, action: .Add)
        }
    }

}

extension PlanGroupViewController: FSCalendarDelegate, FSCalendarDataSource{
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        // 날짜가 선택되면 호출된다
//        selectedDate = date
        selectedDate = date.setCurrentTime()
        planGroup.queryData(date: date)
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        // 스와이프로 월이 변경되면 호출된다
        selectedDate = calendar.currentPage
        planGroup.queryData(date: calendar.currentPage)
    }
    
    // 이함수를 fsCalendar.reloadData()에 의하여 모든 날짜에 대하여 호출된다.
    func calendar(_ calendar: FSCalendar, subtitleFor date: Date) -> String? {
        let plans = planGroup.getPlans(date: date)
        if plans.count > 0 {
            return "[\(plans.count)]"    // date에 해당한 plans의 갯수를 뱃지로 출력한다
        }
        return nil
    }
    
}
