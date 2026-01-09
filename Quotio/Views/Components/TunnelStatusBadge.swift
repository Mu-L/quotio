//
//  TunnelStatusBadge.swift
//  Quotio - Compact tunnel status indicator
//

import SwiftUI

struct TunnelStatusBadge: View {
    let status: CloudflareTunnelStatus
    let compact: Bool
    
    init(status: CloudflareTunnelStatus, compact: Bool = false) {
        self.status = status
        self.compact = compact
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if status == .starting || status == .stopping {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 12, height: 12)
            } else {
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
            }
            
            if !compact {
                Text(status.displayName)
                    .font(.caption)
                    .foregroundStyle(status.color)
            }
        }
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 8) {
        TunnelStatusBadge(status: .idle)
        TunnelStatusBadge(status: .starting)
        TunnelStatusBadge(status: .active)
        TunnelStatusBadge(status: .stopping)
        TunnelStatusBadge(status: .error)
        
        Divider()
        
        TunnelStatusBadge(status: .active, compact: true)
    }
    .padding()
}
