//
//  main.swift
//  FindSimpleDevisor
//
//  Created by Аскар Назмутдинов on 15.05.2023.
//

import Foundation

let timer = ContinuousClock()

func isSimpleNumber(_ inputNumber: Int) -> Bool {
    guard inputNumber >= 2 else { return false }
    var selfDevisorCount = 0
    
    for devisor in 1...inputNumber {
        guard selfDevisorCount <= 2 else { break }
        if inputNumber % devisor == 0 {
            selfDevisorCount += 1
        }
    }
    
    if selfDevisorCount == 2 {
        return true
    } else {
        return false
    }
    
}

func findSimpleDevisor(in inputNumber: Int) -> Int {
    guard inputNumber >= 2 else {
        print("Uncorrect input number \(inputNumber)")
        return 0
    }
    var correctDevisor = inputNumber

    while !(inputNumber % correctDevisor == 0 && isSimpleNumber(correctDevisor)) {
        correctDevisor -= 1
    }

    return correctDevisor
}

var array: [Int] = []
while array.count < 1000 {
    let number = Int.random(in: 10000...10000000)

    if array.contains(number) {
        continue
    }

    array.append(number)
}
print(array)

func findSimpleDevisorGCDWithConcurrentPerform(in array: [Int]) -> [Int] {
    let lock = NSLock()
    var outputArray: [Int] = []
    
    DispatchQueue.concurrentPerform(iterations: array.count) { index in
        let value = findSimpleDevisor(in: array[index])
        lock.lock()
        outputArray.append(value)
        lock.unlock()
    }
    
    return outputArray
}


func findSimpleDevisorGCDWithLimitedAmountOfConcurrentTasks(in array: [Int], with semaphoreValue: Int) -> [Int] {
    let queue = DispatchQueue(label: "concQueue", attributes: .concurrent)
    let group = DispatchGroup()
    let semaphoreForQueue = DispatchSemaphore(value: semaphoreValue)
    let lock = NSLock()
    var outputArray: [Int] = []
    
    for i in array {
        group.enter()
        queue.async {
            let value = findSimpleDevisor(in: i)
            
            lock.lock()
            outputArray.append(value)
            semaphoreForQueue.signal()
            lock.unlock()
            
            group.leave()
        }
        semaphoreForQueue.wait()
    }
    group.wait()
    
    return outputArray
}



func findSimpleDevisorSerial(in array: [Int]) -> [Int] {
    var outputArray: [Int] = []
    
    for i in array {
        outputArray.append(findSimpleDevisor(in: i))
    }
    
    return outputArray
}

func findSimpleDevisorGCDWithOneSemaphore(in array: [Int]) -> [Int] {
    let group = DispatchGroup()
    let queue = DispatchQueue(label: "queue", attributes: .concurrent)
    let semaphore = DispatchSemaphore(value: 0)
    let lock = NSLock()
    var outputArray: [Int] = []
    
    for i in array {
        group.enter()
        queue.async {
            let value = findSimpleDevisor(in: i)
            
            lock.lock()
            outputArray.append(value)
            lock.unlock()
            
            group.leave()
        }
    }
    
    group.notify(queue: queue) {
        semaphore.signal()
    }
    semaphore.wait()
    
    return outputArray
}
    
    func findSimpleDevisorGCDWithTwoSemaphores(in array: [Int], with semaphoreValue: Int ) -> [Int] {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "queue", attributes: .concurrent)
        let semaphoreIn = DispatchSemaphore(value: semaphoreValue)
        let semaphoreOut = DispatchSemaphore(value: 0)
        let lock = NSLock()
        var outputArray: [Int] = []

        for i in array {
            group.enter()
            queue.async {
                let value = findSimpleDevisor(in: i)
                
                lock.lock()
                outputArray.append(value)
                semaphoreIn.signal()
                lock.unlock()
                
                group.leave()
            }
            semaphoreIn.wait()
        }

    group.notify(queue: queue) {
        semaphoreOut.signal()
    }
    semaphoreOut.wait()

    return outputArray
}

func findSimpleDevisorGCDWithOneSemaphoreAndBarrier(in array: [Int]) -> [Int] {
    let group = DispatchGroup()
    let queue = DispatchQueue(label: "queue", attributes: .concurrent)
    let semaphore = DispatchSemaphore(value: 0)
    var outputArray: [Int] = []
    
    for i in array {
        group.enter()
        queue.async {
            let value = findSimpleDevisor(in: i)
            queue.async(flags: .barrier) {
                outputArray.append(value)
                group.leave()
            }
        }
    }
    
    group.notify(queue: queue) {
        semaphore.signal()
    }
    semaphore.wait()
    
    return outputArray
}

func findSimpleDevisorOperationQueue(in array: [Int]) -> [Int] {
    let operationQueue = OperationQueue()
    let queue = DispatchQueue(label: "writing_queue", attributes: .concurrent)
    operationQueue.maxConcurrentOperationCount = 100
    var outputArray: [Int] = []
    
    for i in array {
        let operation = BlockOperation {
            let value = findSimpleDevisor(in: i)
            queue.sync {
                outputArray.append(value)
            }
        }
        operationQueue.addOperation(operation)
    }
    operationQueue.waitUntilAllOperationsAreFinished()
    
    return outputArray
}


func findSimpleDevisorOperationQueue2(in array: [Int]) -> [Int] {
    let operationQueue = OperationQueue()
    let queue = DispatchQueue(label: "writing_queue")
    operationQueue.maxConcurrentOperationCount = 100
    var outputArray: [Int] = []
    
    for i in array {
        let operation = BlockOperation {
            let value = findSimpleDevisor(in: i)
            queue.async {
                outputArray.append(value)
            }
        }
        operationQueue.addOperation(operation)
    }
    operationQueue.waitUntilAllOperationsAreFinished()
    
    queue.sync {}
    
    return outputArray
}

let result1 = timer.measure {
    print(findSimpleDevisorGCDWithConcurrentPerform(in: array).count)
}
print("findSimpleDevisorGCDWithConcurrentPerform: \(result1)")

let semaphoreValue1 = 4
let result2 = timer.measure {
    print(findSimpleDevisorGCDWithLimitedAmountOfConcurrentTasks(in: array, with: semaphoreValue1).count)
}
print("findSimpleDevisorGCDWithLimitedAmountOfConcurrentTasks with semaphore value \(semaphoreValue1): \(result2)")

let semaphoreValue2 = 8
let result3 = timer.measure {
    print(findSimpleDevisorGCDWithLimitedAmountOfConcurrentTasks(in: array, with: semaphoreValue2).count)
}
print("findSimpleDevisorGCDWithLimitedAmountOfConcurrentTasks with semaphore value \(semaphoreValue2): \(result3)")

let semaphoreValue3 = 16
let result4 = timer.measure {
    print(findSimpleDevisorGCDWithLimitedAmountOfConcurrentTasks(in: array, with: semaphoreValue3).count)
}
print("findSimpleDevisorGCDWithLimitedAmountOfConcurrentTasks with semaphore value \(semaphoreValue3): \(result4)")

let semaphoreValue4 = 50
let result5 = timer.measure {
    print(findSimpleDevisorGCDWithLimitedAmountOfConcurrentTasks(in: array, with: semaphoreValue4).count)
}
print("findSimpleDevisorGCDWithLimitedAmountOfConcurrentTasks with semaphore value \(semaphoreValue4): \(result5)")

let result6 = timer.measure {
    print(findSimpleDevisorSerial(in: array).count)
}
print("Serial: \(result6)")

let result7 = timer.measure {
    print(findSimpleDevisorGCDWithOneSemaphore(in: array).count)
}
print("findSimpleDevisorGCDWithOneSemaphore: \(result7)")

let result8 = timer.measure {
    print(findSimpleDevisorOperationQueue(in: array).count)
}
print("findSimpleDevisorOperationQueue Sync: \(result8)")

let result9 = timer.measure {
    print(findSimpleDevisorOperationQueue2(in: array).count)
}
print("findSimpleDevisorOperationQueue Async: \(result9)")

let result10 = timer.measure {
    print(findSimpleDevisorGCDWithOneSemaphoreAndBarrier(in: array).count)
}
print("findSimpleDevisorGCDWithOneSemaphoreAndBarrier: \(result10)")


let result11 = timer.measure {
    print(findSimpleDevisorGCDWithTwoSemaphores(in: array, with: semaphoreValue4).count)
}
print("findSimpleDevisorGCDWithTwoSemaphores wint semaphore value \(semaphoreValue4): \(result11)")
