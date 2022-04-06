//
//  ContentView.swift
//  Shared
//
//  Created by Mikael Waninger on 2022-03-29.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Text(hello.sayHello())
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
