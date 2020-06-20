//
//  InputViewController.swift
//  taskapp
//
//  Created by 吉田 玲子 on 2020/06/10.
//  Copyright © 2020 reiko.yoshida. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

class InputViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    let realm = try! Realm()
    var task: Task!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleTextField.delegate = self
        contentsTextView.delegate = self
        categoryTextField.delegate = self
        
        titleTextField.text = task.title
        contentsTextView.text = task.contents
        datePicker.date = task.date
        categoryTextField.text = task.category
        
        addLayout()
        
        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        textViewShouldDone()
    }
    
    func addLayout() {
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.systemIndigo]
        
        cancelButton.layer.cornerRadius = 8
        cancelButton.layer.borderColor = UIColor.systemIndigo.cgColor
        cancelButton.layer.borderWidth = 1
        saveButton.layer.cornerRadius = 8
        
        titleTextField.borderStyle = UITextField.BorderStyle.none
        categoryTextField.borderStyle = UITextField.BorderStyle.none
        
        let borderWidth = self.view.frame.size.width - 32
        titleTextField.addBorderBottom(width: borderWidth)
        categoryTextField.addBorderBottom(width: borderWidth)
        contentsTextView.addBorderBottom(width: borderWidth)
    }
    
    //画面が非表示になるとき呼ばれるメソッド
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // タスクのローカル通知を登録する
    func setNotification(task: Task) {
        let content = UNMutableNotificationContent()
        // タイトルと内容を設定(中身がない場合メッセージ無しで音だけの通知になるので「(xxなし)」を表示する)
        if task.title == "" {
            content.title = "(タイトルなし)"
        } else {
            content.title = task.title
        }
        if task.contents == "" {
            content.body = "(内容なし)"
        } else {
            content.body = task.contents
        }
        
        content.sound = UNNotificationSound.default

        // ローカル通知が発動するtrigger（日付マッチ）を作成
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        // identifier, content, triggerからローカル通知を作成（identifierが同じだとローカル通知を上書き保存）
        let request = UNNotificationRequest(identifier: String(task.id), content: content, trigger: trigger)

        // ローカル通知を登録
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            print(error ?? "ローカル通知登録 OK")  // error が nil ならローカル通知の登録に成功したと表示します。errorが存在すればerrorを表示します。
        }

        // 未通知のローカル通知一覧をログ出力
        center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
            for request in requests {
                print("/---------------")
                print(request)
                print("---------------/")
            }
        }
    }
  
    @IBAction func cancelButton(_ sender: Any) {
        self.titleTextField.text = ""
        self.contentsTextView.text = ""
        self.categoryTextField.text = ""
    }
    
    @IBAction func saveButton(_ sender: Any) {
        try! realm.write {
            self.task.title = self.titleTextField.text!
            self.task.contents = self.contentsTextView.text
            self.task.date = self.datePicker.date
            self.task.category = self.categoryTextField.text!
            self.realm.add(self.task, update: .modified)
        }
        
        setNotification(task: task)
    }
    
    @objc func dismissKeyboard(){
        view.endEditing(true)
    }
    
     // キーボードを閉じる
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // textViewにdoneボタンを表示できるようにする
    func textViewShouldDone() {
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 40))

        toolBar.barStyle = UIBarStyle.default
        toolBar.sizeToFit()

        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem:UIBarButtonItem.SystemItem.done, target: self,action: #selector(self.dismissKeyboard))
        
        toolBar.items = [spacer, doneButton]
        contentsTextView.inputAccessoryView = toolBar
    }
}

extension UITextField {
    func addBorderBottom(width: CGFloat) {
        let bottomLine = CALayer()
        bottomLine.borderColor = UIColor.systemGray5.cgColor
        bottomLine.borderWidth = 1
        bottomLine.frame = CGRect(x: 0, y: self.frame.size.height - 1, width: width, height: 1)
        self.layer.addSublayer(bottomLine)
    }
}

extension UITextView {
    func addBorderBottom(width: CGFloat) {
        let bottomLine = CALayer()
        bottomLine.borderColor = UIColor.systemGray5.cgColor
        bottomLine.borderWidth = 1
        bottomLine.frame = CGRect(x: 0, y: self.frame.size.height - 1, width: width, height: 1)
        self.layer.addSublayer(bottomLine)
    }
}
