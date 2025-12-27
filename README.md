# SeatCodeTest - Trip Manager

A modern iOS application built with SwiftUI that provides comprehensive trip management functionality with real-time location tracking, interactive maps, and seamless network connectivity.

##  Features

### Core Functionality
- **Trip Management**: View, track, and manage trips with different statuses (ongoing, scheduled, finalized, cancelled)
- **Interactive Maps**: Real-time map visualization using MapKit with route polylines and stop markers
- **Location Services**: Comprehensive location tracking with proper permission handling
- **Network Integration**: Fetch trip data and stop details from remote services
- **Contact Support**: Built-in contact form for user support and feedback

### User Interface
- **Split View Design**: 40% map view and 60% trip list for optimal information display
- **Dynamic Updates**: Real-time updates using Combine framework and SwiftUI's observation system
- **Responsive Design**: Adaptive layout that works across different iOS device sizes
- **Popup Overlays**: Detailed stop information with elegant popup presentations

##  Architecture

### Design Pattern
- **MVVM (Model-View-ViewModel)**: Clean separation of concerns with observable view models
- **SwiftUI + Combine**: Modern reactive programming approach
- **Actor Isolation**: Main actor isolation for UI thread safety
- **@Observable** for state management
- **UserDefaults** for local data persistence
- **UserNotifications** for app badge management
- **MapKit** for location and mapping features


#### Models
- `Trip`: Core trip model with Codable support and unique ID generation
- `TripStatus`: Enumerated trip states with display properties
- `Location` & `Stop`: Geographic and routing data structures

#### ViewModels
- `TripManagerViewModel`: Central state management for trips and map interactions
- Observation pattern for real-time UI updates

#### Services
- `NetworkService`: RESTful API communication for trip data
- `LocationManager`: CoreLocation wrapper with permission management
- `ContactService`: User support and notification handling

#### Views
- `MainView`: Primary application interface with navigation
- `TripMapView`: Interactive map with route visualization
- `TripListView`: Scrollable trip cards with filtering
- `ContactFormView`: Support contact interface
- `StopDetailPopup`: Detailed stop information overlay

##  Technical Requirements

### Development Environment
- **Xcode**: 15.0 or later
- **iOS**: 17.0+ deployment target
- **Swift**: 5.9+

### Dependencies
- **MapKit**: Native iOS mapping and location services
- **CoreLocation**: Location permissions and GPS functionality
- **Combine**: Reactive programming framework
- **Polyline**: Google polyline encoding/decoding support

### Frameworks Used
- SwiftUI for declarative user interface
- Combine for reactive data flow
- MapKit for mapping functionality
- CoreLocation for location services
- Foundation for networking and data handling

##  Getting Started

### Installation
1. Clone the repository
2. Open `SeatCodeTest.xcodeproj` in Xcode
3. Build and run the project on iOS Simulator or device
4. Grant location and notification permissions when prompted

### Configuration
- Ensure location permissions are properly configured in `Info.plist`
- Configure network endpoints in `NetworkService.swift`
- Set up proper app bundle identifier for device testing

### Testing
The project includes comprehensive unit tests:
- `SeatCodeTestLocationManager`: Location service testing
- `SeatCodeTestTripManagerViewModel`: Core business logic testing

Run tests using Xcode's Test Navigator or `⌘+U`.

##  Location Services

### Permission Handling
- Automatic permission request flow
- Graceful handling of denied/restricted states
- User-friendly error messaging for location issues

### Features
- Real-time location updates
- Background location capability (when authorized)
- Location accuracy monitoring
- Comprehensive error handling

##  Map Integration

### Visualization
- Interactive route polylines using Google encoded polylines
- Custom stop annotations with detailed information
- Dynamic region adjustment based on trip data
- User location tracking on map

### Interactivity
- Tap-to-view stop details
- Route selection and highlighting
- Zoom to trip bounds functionality

##  Network Architecture

### API Integration
- RESTful service communication
- JSON decoding with error handling
- Asynchronous data loading with proper error states
- Network reachability considerations

### Data Flow
- Centralized network service layer
- Reactive data binding with Combine
- Automatic UI updates on data changes


##  iOS Integration

### Native Features
- iOS-style navigation patterns
- System notification integration
- Adaptive layout for different screen sizes
- Native map integration with system styles

### Accessibility
- VoiceOver support considerations
- Dynamic type support
- High contrast compatibility

##  Development Notes

### Code Quality
- SwiftUI best practices implementation
- Modern Swift concurrency patterns
- Comprehensive error handling
- Clean architecture principles

### Performance Considerations
- Efficient map rendering with polylines
- Proper memory management for location services
- Optimized network request handling
- Smooth UI updates with proper threading

## Unit Testing

The project includes comprehensive unit tests that validate business logic, data models, and core functionality. Unit tests are located in the main test target and cover critical app components.

### Test Files

#### 1. SeatCodeTestNetwork.swift
Tests the network service layer responsible for API communication:
- **Trip Loading**: Tests successful and failed trip data loading from API endpoints
- **Stop Details Loading**: Validates stop detail data fetching and parsing
- **JSON Decoding**: Tests proper decoding of complex JSON structures with nested objects
- **Error Handling**: Validates proper handling of network errors, invalid JSON, and invalid URLs
- **Mock Network Session**: Uses MockNetworkSession for isolated testing without actual network calls
- **ID Generation**: Tests sequential ID generation for trips and stop details
- **Data Association**: Verifies proper relationships between trips and stops
- **Edge Cases**: Tests empty arrays, boundary values, and malformed data

**Key Testing Features**:
- Mock network session for deterministic testing
- Comprehensive error scenario coverage
- JSON encoding/decoding validation
- Performance testing with large datasets
- URL validation and configuration testing

#### 2. SeatCodeTestTripManagerViewModel.swift
Tests the main view model managing trip data and user interactions:
- **Initialization**: Validates proper view model setup and default states
- **Trip Management**: Tests trip loading, selection, and data refresh operations
- **Stop Selection**: Validates stop detail selection and popup management
- **Map Integration**: Tests map region updates and coordinate handling
- **UI State Management**: Validates showing/hiding of contact forms and popups
- **Error State Handling**: Tests error message display and loading states
- **Data Integration**: Tests coordination between trips and stop details

**Key Testing Features**:
- Mock network and contact services for isolated testing
- Complete workflow testing from data loading to user interaction
- UI state validation and management
- Map region and coordinate testing
- Performance testing with large datasets
- Concurrent access safety verification

#### 3. SeatCodeTestContactService.swift
Tests the contact service managing issue reports and local persistence:
- **Report Management**: Tests creating, saving, and deleting contact reports
- **Data Persistence**: Validates UserDefaults integration for local storage
- **Report Validation**: Tests contact report model properties and validation
- **Batch Operations**: Tests deleting multiple reports with IndexSet
- **Data Integrity**: Validates consistent data state after operations
- **Notification Integration**: Tests notification permission handling

**Key Testing Features**:
- Clean state management between tests
- UserDefaults persistence testing
- Contact report model validation
- Index-based deletion testing
- Edge case handling (empty arrays, invalid indices)
- Codable conformance verification

#### 4. SeatCodeTestLocationManager.swift
Tests the location manager handling GPS and location services:
- **Authorization Management**: Tests location permission states and requests
- **Location Updates**: Validates location data publishing and updates
- **Error Handling**: Tests location service errors and error message management
- **Combine Integration**: Tests @Published property updates and subscription handling
- **Permission Flow**: Validates complete authorization workflow
- **Location Accuracy**: Tests handling of different location accuracy levels

**Key Testing Features**:
- Combine publishers testing with sink subscriptions
- CLLocationManager delegate simulation
- Authorization status change handling
- Location data accuracy validation
- Error message propagation testing
- Complete location workflow integration

### Testing Patterns

The unit tests follow these established patterns:

#### Mock Objects and Dependency Injection
```swift
@MainActor
class MockTripNetworkService: NetworkService {
    var mockTrips: [Trip] = []
    var shouldThrowError = false
    
    override func loadTrips() async throws -> [Trip] {
        if shouldThrowError { throw errorToThrow }
        return mockTrips
    }
}
```

#### Async Testing with Swift Concurrency
```swift
func testLoadTripsSuccess() async throws {
    mockSession.mockData = createMockTripsData()
    let trips = try await networkService.loadTrips()
    
    XCTAssertEqual(trips.count, 2)
    XCTAssertEqual(trips[0].id, 1)
}
```

#### Publisher Testing with Combine
```swift
func testLocationUpdatesPublished() async throws {
    var receivedLocations: [CLLocation?] = []
    
    locationManager.$currentLocation
        .sink { location in receivedLocations.append(location) }
        .store(in: &cancellables)
    
    locationManager.currentLocation = mockLocation
    await Task.yield()
    
    XCTAssertTrue(receivedLocations.contains { $0 != nil })
}
```

#### Clean State Management
```swift
override func setUpWithError() throws {
    UserDefaults.standard.removeObject(forKey: "ContactReports")
    contactService = ContactService()
    XCTAssertTrue(contactService.reports.isEmpty)
}
```

### Running Unit Tests

#### Individual Test Classes
```bash
# Test network layer
xcodebuild test -scheme SeatCode -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:SeatCodeTestTests/SeatCodeTestNetworkTests

# Test view model
xcodebuild test -scheme SeatCode -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:SeatCodeTestTests/SeatCodeTestTripManagerViewModel

# Test contact service
xcodebuild test -scheme SeatCode -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:SeatCodeTestTests/SeatCodeTestContactService

# Test location manager
xcodebuild test -scheme SeatCode -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:SeatCodeTestTests/SeatCodeTestLocationManager
```

#### All Unit Tests
```bash
xcodebuild test -scheme SeatCode -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:SeatCodeTestTests
```

#### Via Xcode
- Open Test Navigator (⌘+6)
- Select individual test methods or classes
- Use ⌘+U to run all tests or click the diamond next to specific tests

### Test Configuration and Best Practices

#### MainActor Testing
All tests run on `@MainActor` ensuring proper handling of UI-related components and avoiding data races.

#### Mock Data Creation
Helper methods create consistent test data:
```swift
private func createMockTrip(id: Int = 1) -> Trip {
    return Trip(
        id: id,
        description: "Trip \(id)",
        driverName: "Driver \(id)",
        // ... other properties
    )
}
```

#### Error Scenario Testing
Comprehensive error handling validation:
```swift
func testLoadTripsNetworkError() async throws {
    mockSession.mockError = URLError(.notConnectedToInternet)
    
    do {
        _ = try await networkService.loadTrips()
        XCTFail("Should have thrown an error")
    } catch let networkError as NetworkError {
        // Verify proper error type and wrapping
    }
}
```

#### Performance Testing
Performance validation for critical operations:
```swift
func testPerformanceWithLargeDataSet() throws {
    measure {
        viewModel.trips = largeTripsArray
        viewModel.selectTrip(largeTripsArray[50])
    }
}
```

### Coverage Areas

The unit tests provide comprehensive coverage of:
- **Network Layer**: API communication, data parsing, error handling
- **Business Logic**: Data models, validation, state management  
- **User Interface**: View model states, user interactions, UI updates
- **Core Services**: Location services, contact management, local persistence
- **Error Scenarios**: Network failures, invalid data, permission denials
- **Edge Cases**: Empty data sets, boundary values, concurrent access

## Testing

The project includes both unit tests and UI tests:
- **Unit Tests**: Test business logic and data models (see Unit Testing section above)
- **UI Tests**: Test user interface interactions and workflows (see UI Testing section above)

Run tests using Xcode's Test Navigator or via command line with `xcodebuild`.


## UI Testing

The project includes comprehensive UI tests located in the `SeatCodeTestUITests` folder. The test suite covers the following areas:

### Test Files

#### 1. MainViewUITests.swift
Tests the main application interface and navigation components:
- **Main View Loading**: Verifies the Trip Manager view loads correctly
- **Navigation Bar Elements**: Tests the presence of navigation controls and toolbar buttons
- **Map View Integration**: Validates map view presence and functionality
- **User Interface Responsiveness**: Ensures UI elements respond appropriately

#### 2. ContactFormViewUITests.swift
Tests the contact form functionality for issue reporting:
- **Form Navigation**: Tests opening the contact form from the main view
- **Form Cancellation**: Verifies users can cancel form submission
- **Form Validation**: Tests input validation and error handling
- **Form Submission**: Validates successful report submission workflow
- **Navigation Flow**: Ensures proper navigation between form states

#### 3. ListViewUITests.swift (ReportsListViewUITests)
Tests the reports list view and report management:
- **Navigation to Reports**: Tests accessing the reports list from the contact form
- **Reports Display**: Verifies proper display of submitted reports
- **List Dismissal**: Tests dismissing the reports list view
- **Report Management**: Validates report deletion and organization
- **Data Persistence**: Ensures reports are properly saved and loaded

#### 4. StopDetailPopUpUITests.swift
Tests the stop detail popup functionality:
- **Popup Display**: Tests triggering and displaying stop detail popups
- **Data Validation**: Verifies popup content accuracy
- **User Interaction**: Tests popup interaction and dismissal
- **Map Integration**: Validates popup integration with map interactions
- **Information Display**: Ensures passenger and stop information is correctly shown

### Running UI Tests

To run the UI tests:

1. **Individual Test Classes**: 
   ```bash
   xcodebuild test -scheme SeatCode -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:SeatCodeTestUITests/MainViewUITests
   ```

2. **All UI Tests**:
   ```bash
   xcodebuild test -scheme SeatCode -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:SeatCodeTestUITests
   ```

3. **Via Xcode**: 
   - Select the test target in the Test Navigator
   - Use `Cmd+U` to run all tests or click the diamond next to specific test methods

### Test Configuration

The UI tests are configured with:
- **Automatic App Launch**: Each test class launches the app fresh
- **Failure Continuation**: Tests stop on first failure for faster debugging
- **Timeout Handling**: Appropriate wait times for UI elements to appear
- **Clean State**: Each test starts with a clean application state

### Best Practices

The UI tests follow these patterns:
- **Page Object Model**: Encapsulated UI interactions for maintainability
- **Explicit Waits**: Using `waitForExistence(timeout:)` for reliable timing
- **Descriptive Test Names**: Clear test method names describing the scenario
- **Setup/Teardown**: Proper test lifecycle management
- **Accessibility Labels**: Leveraging accessibility identifiers for stable element selection


##  License

This project is created as a coding test for SeatCode. All rights reserved.

##  Author

**Angel Docampo**
- Created: December 2025


