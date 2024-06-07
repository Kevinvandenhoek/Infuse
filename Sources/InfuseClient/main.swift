import Infuse

@Providable(SomeService.self)
public protocol SomeWorker {
    
    func sayHello()
}

struct SomeService: SomeWorker {
    
    func sayHello() {
        print("hello")
    }
}

#provided(SomeWorker.self).sayHello()
