//
//  DetailController.swift
//  BudapestTourGuide
//
//  Created by Selim on 21.07.2024.
//

import UIKit
import MapKit
import CoreData

class DetailController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noteField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    var locationManager = CLLocationManager()
    var choosenLongitude = Double()
    var choosenLatitude = Double()
    
    var selectedName = ""
    var selectedId : UUID?
    
    
    var anatationLatitude = Double()
    var anatationLongitude = Double()
    var anatationTitle = ""
    var anatationSubTitle = ""
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapRecognizer)
    
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        
        if selectedName != "" {
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
    
            let idString = selectedId!.uuidString
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                
                let results = try context.fetch(fetchRequest)
                
                if results.count > 0 {
                    
                    for result in results as! [NSManagedObject] {
                        
                        if let name = result.value(forKey: "placeName") as? String {
                            anatationTitle = name
                            
                            if let note = result.value(forKey: "notes") as? String{
                                anatationSubTitle = note
                                
                                if let latitude = result.value(forKey: "latitude") as? Double{
                                    
                                    anatationLatitude = latitude
                                    
                                    if let longitude = result.value(forKey: "longitude") as? Double{
                                        anatationLongitude = longitude
                                        
                                        let anatation = MKPointAnnotation()
                                        anatation.title = anatationTitle
                                        anatation.subtitle = anatationSubTitle
                                        let coordinate = CLLocationCoordinate2D(latitude: anatationLatitude, longitude: anatationLongitude)
                                        anatation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(anatation)
                                        nameField.text = anatationTitle
                                        noteField.text = anatationSubTitle
                                        
                                        locationManager.stopUpdatingLocation()
                                        let span = MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                    }
                                    
                                }
                                
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
    
    @objc func hideKeyboard(){
        view.endEditing(true)
    }
    
    @objc func chooseLocation(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == .began{
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinate = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            choosenLongitude = touchedCoordinate.longitude
            choosenLatitude = touchedCoordinate.latitude
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinate
            annotation.title = nameField.text
            annotation.subtitle = noteField.text
            mapView.addAnnotation(annotation)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedName == ""
        {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            
            let span = MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    
    
    
    func alertFunc(Title:String, Message:String){
        let alert = UIAlertController(title: Title, message: Message, preferredStyle: UIAlertController.Style.alert)
        
        let action = UIAlertAction(title: "Error", style: UIAlertAction.Style.default)
        
        alert.addAction(action)
    present(alert, animated: true, completion: nil)
    }
    
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseID = "MyPin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKMarkerAnnotationView
        
        if pinView == nil {
        
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.markerTintColor = UIColor.blue
            pinView?.canShowCallout = true
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }
        else
        {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if selectedName != ""{
            
            let requestLocation = CLLocation(latitude: anatationLatitude, longitude: anatationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placeMarks, error) in
                
                if let placeMark = placeMarks{
                    
                    if placeMark.count > 0 {
                        
                        let newPlaceMark = MKPlacemark(placemark: placeMark[0])
                        let mapItem = MKMapItem(placemark: newPlaceMark)
                        mapItem.name = self.anatationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        mapItem.openInMaps(launchOptions: launchOptions)
                        
                    }
                    
                }
                
            }
        }
        
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Place", into: context)
        
        if nameField.text != ""{
            
            if noteField.text != "" {
                newPlace.setValue(nameField.text, forKey: "placeName")
                newPlace.setValue(noteField.text, forKey: "notes")
                newPlace.setValue(UUID(), forKey: "id")
                newPlace.setValue(choosenLatitude, forKey: "latitude")
                newPlace.setValue(choosenLongitude, forKey: "longitude")
            }
            else{
                alertFunc(Title: "Note is Null", Message: "Please enter a note")
            }
        }
        else {
            alertFunc(Title: "Name is Null", Message: "Please enter a name")
        }
        
        do {
            try context.save()
            print("success")
        }
        catch{
            print("error")
        }
        NotificationCenter.default.post(name: NSNotification.Name("newData"), object: nil)
        self.navigationController?.popViewController(animated: true)
        
    }
    
    
}
