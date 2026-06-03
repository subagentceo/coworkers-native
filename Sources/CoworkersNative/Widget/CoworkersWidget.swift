// CoworkersWidget.swift — WidgetKit home screen widget
import WidgetKit
import SwiftUI

struct QuickAskEntry: TimelineEntry {
    let date: Date; let title: String?; let msg: String?; let model = "Llama 3.1 8B"
}

struct QuickAskProvider: TimelineProvider {
    func placeholder(in ctx: Context) -> QuickAskEntry { QuickAskEntry(date:.now, title:"Legal review", msg:"Analyzed 3 risk areas in the NDA") }
    func getSnapshot(in ctx: Context, completion: @escaping (QuickAskEntry)->Void) { completion(current) }
    func getTimeline(in ctx: Context, completion: @escaping (Timeline<QuickAskEntry>)->Void) { completion(Timeline(entries:[current], policy:.atEnd)) }
    private var current: QuickAskEntry {
        let d = UserDefaults(suiteName: "group.com.managedcoworkers.native")
        return QuickAskEntry(date:.now, title:d?.string(forKey:"lastConvTitle"), msg:d?.string(forKey:"lastMessage"))
    }
}

struct CoworkersWidgetView: View {
    let entry: QuickAskEntry
    @Environment(\.widgetFamily) var family
    var body: some View {
        ZStack {
            Color(red:0.035,green:0.035,blue:0.043)
            VStack(alignment:.leading, spacing:8) {
                HStack(spacing:0) {
                    Text("managed").font(.system(size:11,weight:.semibold,design:.monospaced)).foregroundStyle(.white)
                    Text("coworkers").font(.system(size:11,weight:.semibold,design:.monospaced)).foregroundStyle(Color(red:0.851,green:0.467,blue:0.024))
                }
                Spacer()
                Text(entry.title ?? "Tap to start").font(.system(size:13,weight:.medium)).foregroundStyle(.white).lineLimit(2)
                Label("Quick Ask", systemImage:"arrow.up.circle.fill").font(.system(size:11,weight:.semibold)).foregroundStyle(Color(red:0.851,green:0.467,blue:0.024))
            }.padding(14)
        }
        .widgetURL(URL(string:"coworkers://new"))
    }
}

@main struct CoworkersWidget: Widget {
    let kind = "CoworkersWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind:kind, provider:QuickAskProvider()) { entry in
            CoworkersWidgetView(entry:entry).containerBackground(.black, for:.widget)
        }
        .configurationDisplayName("Quick Ask")
        .description("Access your knowledge work conversations")
        .supportedFamilies([.systemSmall,.systemMedium])
    }
}