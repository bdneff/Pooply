//
//  CameraView.swift
//  Pooply
//
//  Created by Brandon Grossnickle on 10/23/25.
//

import SwiftUI
import AVFoundation

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }

    let session: AVCaptureSession

    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
}

// MARK: - Main Camera View
struct CameraView: View {
    @Binding var isPresented: Bool
    @Binding var showManualEntry: Bool
    @State private var session = AVCaptureSession()
    @State private var isCameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    
    var body: some View {
        ZStack {
            if isCameraAuthorized {
                CameraPreview(session: session)
                    .ignoresSafeArea()
                    .onAppear {
                        if isCameraAuthorized {
                            startCamera()
                        } else {
                            requestCameraAccess()
                        }
                    }
                
                // Overlay
                VStack {
                    HStack {
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Framing box (like the white square)
                    Rectangle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                        .frame(width: 260, height: 260)
                        .cornerRadius(16)
                        .padding(.bottom, 100)
                    
                    Spacer()
                    
                    // Bottom toolbar
                    HStack(spacing: 32) {
                        Button(action: { /* open photo library */ }) {
                            Label("Library", systemImage: "photo.on.rectangle")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Capsule())
                        }
                        
                        Button(action: { /* scan poop */ }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 80, height: 80)
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                        
                        Button(action: {
                            isPresented = false
                            showManualEntry = true
                        }) {
                            Label("Manual", systemImage: "square.and.pencil")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.bottom, 40)
                }
            } else {
                Text("Camera access not granted")
                    .foregroundColor(.gray)
                    .onAppear {
                        requestCameraAccess()
                    }
            }
        }
    }

    // MARK: - Camera Setup
    func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.isCameraAuthorized = granted
            }
        }
    }
    
    func startCamera() {
        session.beginConfiguration()
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else { return }
        session.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        session.commitConfiguration()
        session.startRunning()
    }
}

#Preview {
    CameraView(isPresented: .constant(true), showManualEntry: .constant(false))
}

