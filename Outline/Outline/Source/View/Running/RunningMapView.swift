//
//  RunningMapView.swift
//  Outline
//
//  Created by 김하은 on 10/17/23.
//

import MapKit
import SwiftUI

struct RunningMapView: View {
    @StateObject private var viewModel = RunningMapViewModel()
    @StateObject var runningStartManager = RunningStartManager.shared
    @StateObject var runningDataManager = RunningDataManager.shared
    @GestureState var isLongPressed = false
    
    @FetchRequest (entity: CoreRunningRecord.entity(), sortDescriptors: []) var runningRecord: FetchedResults<CoreRunningRecord>
    
    @State private var moveToFinishRunningView = false
    @State private var showCustomSheet = false
    @State private var showBigGuide = false
    @State private var counter = 0
    
    @State private var checkUserLocation = true
    
    @State private var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    @State private var currentLocation: CLLocation?
    @Binding var selection: Bool
    
    @Namespace var mapScope
    
    var courses: [CLLocationCoordinate2D] = []
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                Map(position: $position, scope: mapScope) {
                    UserAnnotation()
                    if let courseGuide = runningStartManager.startCourse {
                        MapPolyline(coordinates: ConvertCoordinateManager.convertToCLLocationCoordinates(courseGuide.coursePaths))
                            .stroke(.white.opacity(0.5), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                    }
                    
                    MapPolyline(coordinates: runningDataManager.userLocations)
                        .stroke(.customPrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                }
                .mapControlVisibility(.hidden)
                .onChange(of: CLLocationManager().location) { _, userlocation in
                    if viewModel.runningType == .start {
                        if let user = userlocation,
                           let startCourse = runningStartManager.startCourse {
                            if runningDataManager.userLocations.isEmpty {
                                viewModel.startLocation = CLLocation(latitude: user.coordinate.latitude, longitude: user.coordinate.longitude)
                                runningDataManager.userLocations.append(user.coordinate)
                            } else if let last = runningDataManager.userLocations.last {
                                if viewModel.checkLastToDistance(last: last, current: user.coordinate) {
                                    runningDataManager.userLocations.append(user.coordinate)
                                }
                            }
                            
                            if self.runningStartManager.runningType == .gpsArt {
                                viewModel.checkEndDistance()
                            }
                            if !startCourse.coursePaths.isEmpty {
                                runningStartManager.trackingDistance()
                            }
                        }
                    }
                }
                
                VStack(spacing: 0) {
                    Spacer()
                    runningButtonView
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 80)
                        .opacity(selection ? 0 : 1)
                        .animation(.bouncy, value: selection)
                }
                
                if let course = runningStartManager.startCourse,
                   runningStartManager.runningType == .gpsArt {
                    CourseGuideView(
                        userLocations: $viewModel.userLocations,
                        showBigGuide: $showBigGuide,
                        coursePathCoordinates: ConvertCoordinateManager.convertToCLLocationCoordinates(course.coursePaths),
                        courseRotate: course.heading
                    )
                    .onTapGesture {
                        showBigGuide.toggle()
                        HapticManager.impact(style: .soft)
                    }
                    .animation(.bouncy, value: showBigGuide)
                }
            }
            .mapScope(mapScope)
            .overlay {
                if showCustomSheet {
                    customSheet
                        .onAppear {
                            counter += 1
                        }
                } else if viewModel.isShowComplteSheet {
                    runningFinishSheet()
                } else if viewModel.isShowPopup {
                    RunningPopup(text: "정지 버튼을 길게 누르면 러닝이 종료돼요")
                        .frame(maxHeight: .infinity, alignment: .bottom)
                } else if viewModel.isNearEndLocation {
                    RunningPopup(text: "도착 지점이 근처에 있어요.")
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .navigationDestination(isPresented: $moveToFinishRunningView) {
                FinishRunningView()
                    .navigationBarBackButtonHidden()
            }
        }
    }
}

extension RunningMapView {
    @ViewBuilder
    private var runningButtonView: some View {
        ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    MapUserLocationButton(scope: mapScope)
                        .buttonBorderShape(.circle)
                        .tint(.white)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 16)
                        .padding(.bottom, 14)
                    ZStack {
                        Button {
                            HapticManager.impact(style: .medium)
                            viewModel.runningType = .pause
                            runningDataManager.pauseRunning()
                            runningStartManager.stopTimer()
                        } label: {
                            Image(systemName: "pause.fill")
                                .buttonModifier(color: Color.customPrimary, size: 29, padding: 29)
                                .fontWeight(.light)
                            
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        Button {
                            withAnimation {
                                selection.toggle()
                            }
                        } label: {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 20))
                                .bold()
                                .foregroundStyle(Color.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    Circle()
                                        .fill(.thickMaterial)
                                )
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 16)
                    }
                }
                .opacity(viewModel.runningType == .start ? 1 : 0)
                .zIndex(1)

                ZStack {
                    Image(systemName: "stop.fill")
                        .buttonModifier(color: Color.white, size: 24, padding: 26)
                        .scaleEffect(isLongPressed ? 1.6 : 1)
                        .animation(.easeInOut(duration: 0.5), value: isLongPressed)
                        .gesture(
                            LongPressGesture(minimumDuration: 2)
                                .updating($isLongPressed) { currentState, gestureState, _ in
                                    gestureState = currentState
                                    HapticManager.impact(style: .medium)
                                    
                                    if !isLongPressed {
                                        DispatchQueue.main.async {
                                            viewModel.isShowPopup = true
                                            HapticManager.impact(style: .light)
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    HapticManager.impact(style: .heavy)
                                    DispatchQueue.main.async {
                                       if runningStartManager.counter < 3 {
                                           runningDataManager.stopRunningWithoutRecord()
                                           runningStartManager.counter = 0
                                           runningStartManager.running = false
                                           
                                       } else {
                                           checkUserLocation = false
                                           runningDataManager.stopRunning()
                                           runningStartManager.counter = 0
                                           showCustomSheet = true
                                       }
                                   }
                                }
                        )
                        .frame(maxWidth: .infinity, alignment: viewModel.runningType == .start ? .center : .leading)
                    Button {
                        HapticManager.impact(style: .medium)
                        viewModel.runningType = .start
                        runningDataManager.resumeRunning()
                        runningStartManager.startTimer()
                    } label: {
                        Image(systemName: "play.fill")
                            .buttonModifier(color: Color.customPrimary, size: 24, padding: 26)
                    }
                    .frame(maxWidth: .infinity, alignment: viewModel.runningType == .start ? .center : .trailing)
                }
                .padding(.horizontal, 64)
                .padding(.bottom, 5)
                .animation(.bouncy, value: viewModel.runningType)
        }
    }
    
    private var customSheet: some View {
        ZStack {
            Color.black.opacity(0.5)
            
            VStack(spacing: 0) {
                Text("오늘은, 여기까지")
                    .font(.customTitle2)
                    .padding(.top, 56)
                    .padding(.bottom, 8)
                
                Text("즐거운 러닝이었나요? 다음에 또 만나요! ")
                    .font(.customSubbody)
                    .padding(.bottom, 24)
                
                Image("Finish10")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .padding(.bottom, 45)
                
                CompleteButton(text: "결과 페이지로", isActive: true) {
                    showCustomSheet = false
                    moveToFinishRunningView = true
                }
            }
            .frame(height: UIScreen.main.bounds.height / 2)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.customPrimary, lineWidth: 2)
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .foregroundStyle(Color.gray900)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .animation(.easeInOut, value: showCustomSheet)
            
            Confetti(counter: $counter,
                     num: 80,
                     confettis: [
                        .shape(.circle),
                        .shape(.smallCircle),
                        .shape(.triangle),
                        .shape(.square),
                        .shape(.smallSquare),
                        .shape(.slimRectangle),
                        .shape(.hexagon),
                        .shape(.star),
                        .shape(.starPop),
                        .shape(.blink)
                     ],
                     colors: [.blue, .yellow],
                     confettiSize: 8,
                     rainHeight: UIScreen.main.bounds.height,
                     radius: UIScreen.main.bounds.width
            )
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private func runningFinishSheet() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.customPrimary)
                .fill(Color.black70)
            
            VStack(alignment: .center, spacing: 0) {
                Text("그림을 완성했어요!")
                    .font(.customTitle2)
                    .padding(.top, 73)
                    .padding(.bottom, 20)
                
                Text("5m이내에 도착지점이 있어요")
                    .font(.customSubbody)
                    .foregroundStyle(Color.gray300)
                
                Text("러닝을 완료할까요?")
                    .font(.customSubbody)
                    .foregroundStyle(Color.gray300)
                    .padding(.bottom, 41)
                
                CompleteButton(text: "완료하기", isActive: true) {
                    moveToFinishRunningView = true
                }
                .padding(.bottom, 24)
                
                Button {
                    viewModel.isShowComplteSheet = false
                } label: {
                    Text("조금 더 진행하기")
                        .foregroundStyle(Color.white)
                        .font(.customButton)
                        .padding(.bottom, 37)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(EdgeInsets(top: 422, leading: 8, bottom: 34, trailing: 8))
    }
}

extension Image {
    func imageButtonModifier(color: Color, size: CGFloat, padding: CGFloat) -> some View {
        self
            .resizable()
            .scaledToFit()
            .frame(width: size)
            .foregroundStyle(Color.customBlack)
            .padding(padding)
            .background(
                Circle()
                    .fill(color)
            )
    }
    
    func buttonModifier(color: Color, size: CGFloat, padding: CGFloat) -> some View {
        self
            .font(.system(size: size))
            .foregroundStyle(Color.customBlack)
            .padding(padding)
            .background(
                Circle()
                    .fill(color)
                    .stroke(.white, style: .init())
                    .frame(width: 80, height: 80)
            )
    }
}
