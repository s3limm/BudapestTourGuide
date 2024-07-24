//
//  ViewController.swift
//  BudapestTourGuide
//
//  Created by Selim on 21.07.2024.
//

import UIKit
import CoreData

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource{

    @IBOutlet weak var tableView: UITableView!
    
    var choosenName = String()
    var nameArray = [String]()
    var choosenId = UUID()
    var idArray = [UUID]()
    var noteArray = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonClicled))
        
        GetData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(GetData), name: NSNotification.Name("newData"), object: nil)
    }
    
    
    @objc func GetData(){
        
        nameArray.removeAll(keepingCapacity: false)
        idArray.removeAll(keepingCapacity: false)
        
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            
            let results = try context.fetch(fetchRequest)
            
            for result in results as! [NSManagedObject]{
                
                if let id = result.value(forKey: "id") as? UUID{
                    self.idArray.append(id)
                }
                
                if let placeName = result.value(forKey: "placeName") as? String{
                    self.nameArray.append(placeName)
                }
                
                if let notes = result.value(forKey: "notes") as? String{
                    self.noteArray.append(notes)
                }
                
                self.tableView.reloadData()
            }
            
        }
        catch{
            print("error")
        }
        
    }

    @objc func addButtonClicled(){
        choosenName = ""
        performSegue(withIdentifier: "toDetailVC", sender: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = UITableViewCell()
            var content = cell.defaultContentConfiguration()
            content.text = nameArray[indexPath.row]
            content.secondaryText = noteArray[indexPath.row]
            cell.contentConfiguration = content
           return cell
        }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        choosenName = nameArray[indexPath.row]
        choosenId = idArray[indexPath.row]
        performSegue(withIdentifier: "toDetailVC", sender: nil)
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailVC"
        {
            let detailVC = segue.destination as! DetailController
            detailVC.selectedName = choosenName
            detailVC.selectedId = choosenId
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
    {
       
        var appDelegate = UIApplication.shared.delegate as! AppDelegate
        var context = appDelegate.persistentContainer.viewContext
        
        var idString = idArray[indexPath.row].uuidString
        
        var fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
        fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            
            let results = try context.fetch(fetchRequest)
            
            if results.count > 0{
                
                for result in results as![NSManagedObject]{
                    
                    if let id = result.value(forKey: "id") as? UUID{
                        
                        if id == idArray[indexPath.row] {
                            
                            idArray.remove(at: indexPath.row)
                            nameArray.remove(at: indexPath.row)
                            context.delete(result)
                            self.tableView.reloadData()
                            
                            do{
                                
                                try context.save()
                            }
                            catch{print("Can't Save")}
                        }
                        
                    }
                    
                }
                
            }
            
            
        }
        catch{
            print("error")
        }
        
    }
}

