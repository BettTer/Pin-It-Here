//
//  ARComposer_SUIV.swift
//  PinItHere
//
//  Created by YY.COUPLE on 2025-09-23.
//

import SwiftUI
import RealityKit
import LocalSharedPackage
import ProgressHUD

struct ARComposerView: View {
    @State private var didLoad = false
    
//    @State private var preferredRestoreMethod: ARFinalSceneView.RestoreMethod = .worldMap
    @State private var placeCmd: PlacePaperCommand? = nil
    @State private var updateImg: CGImage? = nil
    @State private var needToRemoveAllPapers: Bool? = nil
    
    @State private var indicatorOK = false
    @State private var lastIndicatorTransform: simd_float4x4?
    
    public static let paperSizeMeters = CGSize(width: 0.21, height: 0.297)
    
    public static let bottomButtonFont: CGFloat = 15
    
    public static func pixelSize(forMeters m: CGSize) -> CGSize {
        let pxPerMeter: CGFloat = 3500 // 可酌情降到 3000，进一步省 CPU/GPU
        return CGSize(width: m.width * pxPerMeter, height: m.height * pxPerMeter)
    }
    
//    func switchPreferredRestoreMethod(_ restoreMethod: ARFinalSceneView.RestoreMethod) {
//        if preferredRestoreMethod == restoreMethod {
//            return
//        }
//        
//        preferredRestoreMethod = restoreMethod
//        
//    }
    
    var body: some View {
        ZStack {
            if didLoad {
                ARFinalSceneView(
                    backgroundColor: .systemYellow,
                    placeCommand: $placeCmd,
                    updateTexture: $updateImg,
                    needToRemoveAllPapers: $needToRemoveAllPapers,
                    onIndicatorStateChanged: { status in
                        indicatorOK = status == .ready
                    },
                    onIndicatorTransformChanged: { tf in
                        lastIndicatorTransform = tf
                    }
                )
                .ignoresSafeArea()
                
//                ARGPSSceneView(record: NoteRecordStoreManager.shared.onlyRecord!)
//                    .ignoresSafeArea()
                
            }
            
            VStack {
                Spacer()
                HStack {
                    Button {
                        guard indicatorOK, let tf = lastIndicatorTransform else { return }
                        let content = PaperCard(title: "Hello, AR World")
                        let px = ARComposerView.pixelSize(forMeters: ARComposerView.paperSizeMeters)
                        if let cg = ViewRenderer.render(AnyView(content), pixelSize: px) {
                            placeCmd = PlacePaperCommand(worldTransform: tf,
                                                         paperSizeMeters: ARComposerView.paperSizeMeters,
                                                         texture: cg)
                        }
                    } label: {
                        Label("Place the note", systemImage: "square.and.arrow.down")
                            .font(.system(size: ARComposerView.bottomButtonFont))
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!indicatorOK)
                    
                    Button {
                        needToRemoveAllPapers = true
                        ProgressHUD.succeed("移除成功")
                        
                    } label: {
                        Label("Remove all notes", systemImage: "trash.square")
                            .font(.system(size: ARComposerView.bottomButtonFont))
                    }
                    .buttonStyle(.borderedProminent)
                    
                    /*
                     Menu {
                         Button {
                             switchPreferredRestoreMethod(.worldMap)
                             
                         } label: {
                             Label {
                                 Text(".worldMap")
                             } icon: {
                                 if preferredRestoreMethod == .worldMap {
                                     Image(systemName: "checkmark")
                                 }
                             }
                         }
                         
                         Button {
                             switchPreferredRestoreMethod(.geoAnchor)
                             
                         } label: {
                             Label {
                                 Text(".geoAnchor")
                             } icon: {
                                 if preferredRestoreMethod == .geoAnchor {
                                     Image(systemName: "checkmark")
                                 }
                             }
                         }
                         
                         Button {
                             switchPreferredRestoreMethod(.approximateCalculation)
                             
                         } label: {
                             Label {
                                 Text(".approximateCalculation")
                             } icon: {
                                 if preferredRestoreMethod == .approximateCalculation {
                                     Image(systemName: "checkmark")
                                 }
                             }
                         }
                         
                         
                     } label: {
                         Label("切换复原方式", systemImage: "rectangle.2.swap")
                             .font(.system(size: ARComposerView.bottomButtonFont))
                         
                     }
                     .buttonStyle(.borderedProminent)
                     */

                    
//                    Button {
//                        let content = PaperCard(title: "已更新的内容 ✍️")
//                        let px = ARComposerView.pixelSize(forMeters: ARComposerView.paperSizeMeters)
//                        if let cg = ViewRenderer.render(AnyView(content), pixelSize: px) {
//                            updateImg = cg
//                        }
//                    } label: {
//                        Label("更新内容", systemImage: "arrow.triangle.2.circlepath")
//                    }
//                    .buttonStyle(.bordered)
                }
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            NoteRecordStoreManager.shared.tryToLoadData {
                DispatchQueue.main.async {
                    didLoad = true
                    
                    PreciseLocationProvider.shared.start(stopAfterSuccess: false, completion: nil)
                }
            }
        }
    }
}

struct PaperCard: View {
    var title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title2).bold()
            Text("一次渲染的 SwiftUI 视图 → 贴到真实平面上。\n需要变更时再渲染一次并替换材质即可。")
                .font(.body)
            HStack {
                Image(systemName: "paperclip")
                Text("支持 Emoji / 富文本布局")
            }.font(.footnote)
        }
        .padding(20)
        .frame(width: 300, height: 420)
        .background(.white)
    }
}

