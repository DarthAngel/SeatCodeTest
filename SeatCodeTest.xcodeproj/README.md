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

### Key Components

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

##  Testing Strategy

### Unit Testing
- Comprehensive LocationManager testing
- ViewModel business logic validation
- Combine publisher behavior testing
- Mock data integration for reliable testing

### Testing Features
- Actor isolation testing
- Async/await pattern testing
- Publisher and subscriber behavior validation
- Error handling scenario coverage

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

##  License

This project is created as a coding test for SeatCode. All rights reserved.

##  Author

**Angel Docampo**
- Created: December 2025
- iOS Developer specializing in SwiftUI and modern Swift development


