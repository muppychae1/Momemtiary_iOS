//
//  PlanDetailViewController.swift
//  ch10-leejaemoon-stackView
//
//  Created by jmlee on 2023/04/27.
//

import UIKit

class PlanDetailViewController: UIViewController {

    @IBOutlet weak var dateDatePicker: UIDatePicker!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var typePicker: UIPickerView!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var plan: Plan?
    var saveChangeDelegate: ((Plan)->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        typePicker.dataSource = self
        typePicker.delegate = self
        
        plan = plan ?? Plan(date: Date(), withData: true)
        dateDatePicker.date = plan?.date ?? Date()
        ownerLabel.text = plan?.owner       // plan!.owner과 차이는? optional chainingtype

        // typePickerView 초기화
        if let plan = plan{
            typePicker.selectRow(plan.kind.rawValue, inComponent: 0, animated: false)
        }
        // content
       contentTextView.text = plan?.content
        
        // imageView에 이미지 띄우기
        let url = URL(string: plan?.imageURL ?? "") //입력받은 url string을 URL로 변경
        DispatchQueue.global().async { [weak self] in
            if(url != URL(string: "")) {
                if let data = try? Data(contentsOf: url!) {
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self?.imageView.image = image
                        }
                    }
                }
            }
        }

    }

    override func viewWillDisappear(_ animated: Bool) {
        
        plan!.date = dateDatePicker.date
        plan!.owner = ownerLabel.text    // 수정할 수 없는 UILabel이므로 필요없는 연산임
        plan!.kind = Plan.Kind(rawValue: typePicker.selectedRow(inComponent: 0))!
        plan!.content = contentTextView.text
        
        if let imageData = imageView.image?.jpegData(compressionQuality: 0.8) {
            plan!.imageData = imageData
        }
        
        saveChangeDelegate?(plan!)
    }
    
    
    @IBAction func selectPhoto(_ sender: UIButton) {
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        
        if(UIImagePickerController.isSourceTypeAvailable(.camera)){
            imagePickerController.sourceType = .camera
        } else {
            imagePickerController.sourceType = .photoLibrary
        }
        
        // UIImagePickerController 활성화
        present(imagePickerController, animated: true, completion: nil)
        
    }
    
}

extension PlanDetailViewController : UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    // 사진을 찍은 경우 호출되는 함수
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // imageView에 선택한 이미지 띄우기
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        imageView?.image = image
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    // 사진 캡처를 취소하는 경우 호출 함수
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        //imagePickerController를 죽인다
        picker.dismiss(animated: true, completion: nil)
    }
    
}


extension PlanDetailViewController: UIPickerViewDataSource, UIPickerViewDelegate{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Plan.Kind.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let type = Plan.Kind.init(rawValue: row)
        return type?.toString()
    }
    
}
