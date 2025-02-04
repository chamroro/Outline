//
//  UserDataModel.swift
//  Outline
//
//  Created by Seungui Moon on 10/17/23.
//

import CoreData
import SwiftUI
import CoreLocation

protocol UserDataModelProtocol {
    func createRunningRecord(
        record: RunningRecord,
        completion: @escaping (Result<Bool, CoreDataError>) -> Void
    )
    func updateRunningRecordCourseName(
        _ record: NSManagedObject,
        newCourseName: String,
        completion: @escaping (Result<Bool, CoreDataError>) -> Void
    )
    func deleteRunningRecord(
        _ object: NSManagedObject,
        completion: @escaping (Result<Bool, CoreDataError>) -> Void
    )
    func deleteAllRunningRecord(
        completion: @escaping (Result<Bool, CoreDataError>) -> Void
    )
}

enum CoreDataError: Error {
    case saveFailed
    case dataNotFound
}

struct UserDataModel: UserDataModelProtocol {
    
    let persistenceController = PersistenceController.shared
    
    private func saveContext() throws {
        do {
            try persistenceController.container.viewContext.save()
        } catch {
            throw CoreDataError.saveFailed
        }
    }
    
    func createRunningRecord(
        record: RunningRecord,
        completion: @escaping (Result<Bool, CoreDataError>) -> Void
    ) {
        let newRunningRecord = CoreRunningRecord(context: persistenceController.container.viewContext)
        newRunningRecord.runningType = record.runningType.rawValue
        newRunningRecord.id = UUID().uuidString
        
        let context = persistenceController.container.viewContext
        let newCourseData = CoreCourseData(context: context)
        newCourseData.setValue(record.courseData.courseName, forKey: "courseName")
        newCourseData.setValue(record.courseData.runningLength, forKey: "runningLength")
        newCourseData.setValue(record.courseData.heading, forKey: "heading")
        newCourseData.setValue(record.courseData.distance, forKey: "distance")
        newCourseData.setValue(record.courseData.heading, forKey: "heading")
        newCourseData.setValue(record.courseData.regionDisplayName, forKey: "regionDisplayName")
        var pathList: [CoreCoordinate] = []
        for path in record.courseData.coursePaths {
            let newPath = CoreCoordinate(entity: CoreCoordinate.entity(), insertInto: persistenceController.container.viewContext)
            newPath.latitude = path.latitude
            newPath.longitude = path.longitude
            pathList.append(newPath)
        }
        
        newCourseData.coursePaths = NSOrderedSet(array: pathList)
        newCourseData.parentRecord = newRunningRecord
        
        let newHealthData = CoreHealthData(context: persistenceController.container.viewContext)
        newHealthData.setValue(record.healthData.totalTime, forKey: "totalTime")
        newHealthData.setValue(record.healthData.averageCadence, forKey: "averageCadence")
        newHealthData.setValue(record.healthData.totalRunningDistance, forKey: "totalRunningDistance")
        newHealthData.setValue(record.healthData.totalEnergy, forKey: "totalEnergy")
        newHealthData.setValue(record.healthData.averageHeartRate, forKey: "averageHeartRate")
        newHealthData.setValue(record.healthData.averagePace, forKey: "averagePace")
        newHealthData.setValue(record.healthData.startDate, forKey: "startDate")
        newHealthData.setValue(record.healthData.endDate, forKey: "endDate")
        
        newHealthData.recordHeathData = newRunningRecord
        
        do {
            try saveContext()
            completion(.success(true))
        } catch {
            completion(.failure(.saveFailed))
        }
    }
    
    func updateRunningRecordCourseName(
        _ record: NSManagedObject,
        newCourseName: String,
        completion: @escaping (Result<Bool, CoreDataError>) -> Void
    ) {
        guard let record = record as? CoreRunningRecord else {
            completion(.failure(.dataNotFound))
            return
        }
        
        record.courseData?.setValue(newCourseName, forKey: "courseName")
        
        do {
            try saveContext()
            completion(.success(true))
        } catch {
            completion(.failure(.saveFailed))
        }
    }
    
    func deleteRunningRecord(
        _ object: NSManagedObject,
        completion: @escaping (Result<Bool, CoreDataError>) -> Void
    ) {
        persistenceController.container.viewContext.delete(object)
        
        do {
            try saveContext()
            completion(.success(true))
        } catch {
            completion(.failure(.saveFailed))
        }
    }
    
    func deleteAllRunningRecord(completion: @escaping (Result<Bool, CoreDataError>) -> Void) {
        persistenceController.container.viewContext.reset()
        completion(.success(true))
    }
}
