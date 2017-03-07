Pod::Spec.new do |s|
    s.name             = 'ModelKit'
    s.version          = '0.2.0'
    s.summary          = 'A collection of utilities for working with model objects'
    s.homepage         = 'https://github.com/sadawi/ModelKit'
    s.license          = 'MIT'
    s.author           = { 'Sam Williams' => 'samuel.williams@gmail.com' }
    s.source           = { :git => 'https://github.com/sadawi/ModelKit.git', :tag => s.version.to_s }
    
    s.platforms       = { :ios => '9.0' }
    
    s.requires_arc = true
    
    s.dependency 'PromiseKit/CorePromise', '~> 4.0.5'

    s.subspec 'Fields' do |ss|
        ss.source_files = 'ModelKit/Fields/**/*'
        ss.dependency 'StringInflections', '~> 0.0.6'
    end
    
    s.subspec 'Models' do |ss|
        ss.source_files = ['ModelKit/Models/**/*', 'ModelKit/ModelStore/**/*']
        ss.dependency 'ModelKit/Fields'
    end

    s.subspec 'RemoteModelStore' do |ss|
        ss.source_files = 'ModelKit/RemoteModelStore/**/*'
        ss.dependency 'ModelKit/Models'
        ss.dependency 'Alamofire', '~> 4.2.0'
        ss.dependency 'SwiftyJSON', '~> 3.1.3'
    end
end
