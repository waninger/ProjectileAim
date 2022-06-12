//
//  FileManager.swift
//  ProjectileAim (iOS)
//
//  Created by sofia on 2022-06-01.
//

import Foundation
import ARKit

class FileHandler {
    
    public func documentDirectory() -> String {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                    .userDomainMask,
                                                                    true)
        return documentDirectory[0]
    }
    
    private func append(toPath path: String,
                        withPathComponent pathComponent: String) -> String? {
        if var pathURL = URL(string: path) {
            pathURL.appendPathComponent(pathComponent)
            
            return pathURL.absoluteString
        }
        
        return nil
    }
    
    public func read(fromDocumentsWithFileName fileName: String) -> String {
        guard let filePath = self.append(toPath: self.documentDirectory(),
                                         withPathComponent: fileName) else {
            return ""
        }
        
        do {
            let savedString = try String(contentsOfFile: filePath)
            return savedString
        } catch {
            print("Error reading file")
        }
        return ""
    }
    
    public func save(list: [Any]?,
                     toDirectory directory: String,
                     withFileName fileName: String) {
        guard let filePath = self.append(toPath: directory, withPathComponent: fileName) else {
            return
        }
        
        let lastSaved = read(fromDocumentsWithFileName: fileName)
        
        var newList = [Any]()
        newList.append(lastSaved)
        newList.append("Next")
        newList.append(list)
        
        (newList as NSArray).write(toFile: filePath, atomically: true)
        
 /*       do {
            if(floatList != nil ) {
                (floatList! as NSArray).write(toFile: filePath, atomically: false)
            } else if (stringList != nil) {
                (stringList! as NSArray).write(toFile: filePath, atomically: false)
            }
                             /* string.write(toFile: filePath,
                                        atomically: true,
                                        encoding: .utf8)*/
            
        } catch {
            print("Error", error)
            return
        }*/
        
        print("Save successful")
    }
}
