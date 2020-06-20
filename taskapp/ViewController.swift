//
//  ViewController.swift
//  taskapp
//
//  Created by 吉田 玲子 on 2020/06/06.
//  Copyright © 2020 reiko.yoshida. All rights reserved.
//

import UIKit
import RealmSwift

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var emptyView: UIStackView!
    
    // Realmインスタンスを取得する
    let realm = try! Realm()
    // DB内のタスクが格納されるリスト。
    // 日付の近い順でソート：昇順
    // 以降内容をアップデートするとリスト内は自動的に更新される。
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
        view.backgroundColor = UIColor.systemGray6
        tableView.tableFooterView = UIView()
        tableView.backgroundColor =  UIColor.systemGray6
        searchBar.barTintColor =  UIColor.systemGray6
        searchBar.backgroundImage = UIImage()
        searchBar.searchTextField.backgroundColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = UIColor.systemGray6
        self.navigationController?.navigationBar.isTranslucent  = false
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        checkTableData(count: taskArray.count)
    }
    
    // データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return taskArray.count
    }
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        // Cellに値を設定する.
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString:String = formatter.string(from: task.date)
        let categoryString:String = task.category
        cell.detailTextLabel?.text = dateString + " , " + categoryString

        return cell
    }
    
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         performSegue(withIdentifier: "cellSegue",sender: nil)
    }
    
    // セルが削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCell.EditingStyle {
        return .delete
    }

    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
           // 削除するタスクを取得する
           let task = self.taskArray[indexPath.row]

           // ローカル通知をキャンセルする
           let center = UNUserNotificationCenter.current()
           center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])

           // データベースから削除する
           try! realm.write {
               self.realm.delete(task)
               tableView.deleteRows(at: [indexPath], with: .fade)
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
        checkTableData(count: taskArray.count)
    }
    
    //検索窓に入力した時に呼ばれる
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //検索する
        searchCategory(searchText: searchBar.text ?? "")
    }
    
    //カテゴリを検索
   func searchCategory(searchText: String) {
        if(searchBar.text == "") {
            taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
        } else {
            //空以外が入力されたら検索する
            taskArray = try! Realm().objects(Task.self).filter("category == %@", searchText)
        }
        //tableViewを再読み込みする
        tableView.reloadData()
        checkTableData(count: taskArray.count)
   }
    
    // segue で画面遷移する時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        let inputViewController:InputViewController = segue.destination as! InputViewController

        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            //配列taskArrayから該当するTaskクラスのインスタンスを取り出して
            //inputViewControllerのtaskプロパティに設定
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            
            let task = Task()

            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                //すでに存在しているタスクのidのうち最大のものを取得し、
                //1を足すことで他のIDと重ならない値を指定
                task.id = allTasks.max(ofProperty: "id")! + 1
            }

            inputViewController.task = task
        }
    }
    
    // 入力画面から戻ってきた時に TableView を更新させる
   override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
        //UITableViewクラスのreloadDataメソッドを呼ぶことで
        //タスク作成/編集画面で変更した情報をTableViewに反映させる
        tableView.reloadData()
        checkTableData(count: taskArray.count)
    
        //戻るボタンを表示しない
        self.navigationItem.hidesBackButton = true
   }
    
    // テーブルが空の場合はemptyViewを表示する
    func checkTableData(count:Int) {
        if count > 0 {
            emptyView.isHidden = true
        } else {
            emptyView.isHidden = false
        }
    }
}
