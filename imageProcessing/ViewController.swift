//
//  ViewController.swift
//  imageProcessing
//
//  Created by 趙自然 on 12/12/15.
//  Copyright © 2015 趙自然. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
//    private var inputstream : NSInputStream?
//    private var buf : UInt8?
//    private var line : [UInt8]?
//    private var MAX_COLS:Int?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        //        Demo of reading a file
        let pgm = Pgm()
        var histgram = [Int]()
        var inputstream : NSInputStream?
        var spec    = [Character]()
        var buf     = UInt8()
        var commentline : Bool = false
        var line    = [UInt8]()
        let MAX_COLS = 255
        var i : Int
        var x : Int, y : Int

        inputstream = NSInputStream(fileAtPath: "/Users/znatz/Projects/imageProcessing/bin/a.pgm")!
        inputstream!.open()
        
        // P5
        i = 0
        repeat {
            let bytesRead = inputstream!.read(&buf, maxLength: 1)
            if bytesRead < 0 {break}
            line.append(buf)
            i++;
        } while(i<MAX_COLS && buf !=  0x0A)
        line.removeLast()
        pgm.version = NSString(bytes: line, length: line.count, encoding:NSASCIIStringEncoding)!
        
        // COMMENT LINES
        line.removeAll()
        i = 0
        repeat {
            let bytesRead = inputstream!.read(&buf, maxLength: 1)
            if bytesRead < 0 {break}
            if i == 0 && buf == 0x23 {commentline = true} else {commentline = false}
//            if commentline { NSLog("------ COMMENT LINE ----")}
            line.append(buf)
            i++;
        } while(i<MAX_COLS && buf !=  0x0A)
        line.removeLast()
        pgm.comment = NSString(bytes: line, length: line.count, encoding: NSASCIIStringEncoding)!
        
        
        // WIDTH & HEIGHT
        i = 0
        spec.removeAll()
        repeat {
            let bytesRead = inputstream!.read(&buf, maxLength: 1)
            if i == 0 && buf == 0x0A {
//                NSLog("------ Empty Line ----")
                inputstream!.read(&buf, maxLength: 1)
            }
            
//            if i == 0 {NSLog("------ WIDTH & HEIGHT ----") }
            
            if bytesRead < 0 {break}
            spec.append(Character(UnicodeScalar(buf)))
            i++;
        } while(i<MAX_COLS && buf !=  0x0A)
        spec.removeLast()
        let strSpec : String = String(spec)
        let width = strSpec.componentsSeparatedByString(" ")[0]
        let height = strSpec.componentsSeparatedByString(" ")[1]
        (pgm.width, pgm.height) = (Int(width)!, Int(height)!)
        
        
         // DEPTH
        i = 0
        spec.removeAll()
        repeat {
            let bytesRead = inputstream!.read(&buf, maxLength: 1)
            if i == 0 && buf == 0x0A {
//                NSLog("------ Empty Line ----")
                inputstream!.read(&buf, maxLength: 1)
            }
            
//            if i == 0 {NSLog("------ DEPTH ----") }
            
            if bytesRead < 0 {break}
            spec.append(Character(UnicodeScalar(buf)))
            i++;
        } while(i<MAX_COLS && buf !=  0x0A)
        spec.removeLast()
        pgm.depth = Int(String(spec))!
        
        // Body
        pgm.pixels = Array(count: pgm.width, repeatedValue: Array(count: pgm.height, repeatedValue: 0))
        for (y=0; y<pgm.height; y++){
            for (x=0; x<pgm.width; x++) {
                let bytesRead = inputstream!.read(&buf, maxLength: 1)
                if bytesRead < 0 {break}
                pgm.pixels[x][y] = buf
            }
        }
        
        // CLOSE
        inputstream!.close()
        
        // Show Parsing Result
        NSLog("%@\n%@\nwidth : %d height : %d\ndepth : %d", pgm.version, pgm.comment, pgm.width, pgm.height, pgm.depth)
        
        // Transfer Pixels and get histgram
        histgram = Array<Int>(count: 256, repeatedValue: 0)
        for (y=0; y<pgm.height; y++){
            for (x=0; x<pgm.width; x++) {
                histgram[Int(pgm.pixels[x][y])] += 1
                pgm.pixels[x][y] = 255 - pgm.pixels[x][y]
            }
        }
        

        // Output Image
        var obuf = NSData()
        let outputstream = NSOutputStream(toFileAtPath: "/Users/znatz/Projects/imageProcessing/bin/d.pgm", append: false)
        outputstream?.open()
        
        let tmp = NSString(format: "%@%c%@%c%c%d %d%c%d%c",pgm.version, 0xA, pgm.comment, 0xA, 0xA, pgm.width, pgm.height, 0xA, pgm.depth, 0xA)
        obuf = tmp.dataUsingEncoding(NSASCIIStringEncoding)!
        outputstream?.write(UnsafePointer<UInt8>(obuf.bytes), maxLength: obuf.length)
        
        for (y=0; y<pgm.height; y++){
            for (x=0; x<pgm.width; x++) {
//                var p = pgm.pixels[x][y]
                var p = pgm.pixels[x][y]
                p = p > 150 ? 255 : 0
                outputstream?.write(&p, maxLength: 1)
            }
        }
        outputstream?.close()
        
        //  Draw histgram of image
        let maxValue = histgram.maxElement()
        let minValue = histgram.minElement()
        let avgValue = (maxValue! + minValue!) / 2
        let WIN_WIDTH = 1100
        let WIN_HEIGHT = 750
        let ratioY = maxValue!  / WIN_HEIGHT + 5
        let ratioX = WIN_WIDTH / 255
        let view = NSImageView(frame:NSRect(x: 50, y: 50, width: WIN_WIDTH, height: WIN_HEIGHT))
        let img  = NSImage(size: NSMakeSize(CGFloat(WIN_WIDTH),CGFloat(WIN_HEIGHT)))
        view.image = img
        img.lockFocus()
        
        let path = NSBezierPath()
        path.moveToPoint(NSPoint(x: 0,y: 0))
        for (x = 0; x < 255; x++) {
            if (histgram[x] == maxValue ) {
                let peak = NSPoint(x: x*ratioX, y: histgram[x]/ratioY)
                NSLog("%f, %f", peak.x, peak.y)
                NSString(format: "%d %d", x, histgram[x]).drawAtPoint(peak, withAttributes: nil)
            }
            path.lineToPoint(NSPoint(x: x*ratioX,y: histgram[x]/ratioY))
        }
            path.stroke()
        
        path.moveToPoint(NSPoint(x: 0, y: avgValue/ratioY))
        path.lineToPoint(NSPoint(x: 255*ratioX, y: avgValue/ratioY))
        path.stroke()
        img.unlockFocus()
        view.needsDisplay = true
        self.view.addSubview(view)
        
    }
    
    override var representedObject: AnyObject? {
        didSet {
        }
    }
    
    
}

