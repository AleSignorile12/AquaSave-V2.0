import SwiftUI

struct HomeView: View {
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 20) {
            
            // HEADER
            Text("Dashboard")
                .font(.largeTitle.bold())
                .padding(.horizontal)
            
            // GRID
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 16
            ) {
                
                // TODAY
                VStack(spacing: 10) {
                    
                    Text("Today")
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("0 L")
                        .font(.title2.bold())
                    
                    Image(systemName: "drop.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                
                
                // HYDRATION
                VStack(spacing: 10) {
                    
                    Text("Hydration")
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("0 ml")
                        .font(.title2.bold())
                    
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                
                
                // POINTS
                VStack(spacing: 10) {
                    
                    Text("Points")
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("600")
                        .font(.title2.bold())
                    
                    Image(systemName: "leaf.fill")
                        .font(.title2)
                        .foregroundStyle(.mint)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

#Preview {
    HomeView()
}
