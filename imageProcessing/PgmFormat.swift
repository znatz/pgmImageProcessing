//
//  pgmFormat.swift
//  imageProcessing
//
//  Created by 趙自然 on 12/12/15.
//  Copyright © 2015 趙自然. All rights reserved.
//

import Foundation

public class Pgm {
    public var version : NSString = ""
    public var comment : NSString = ""
    public var width   : Int = 0
    public var height  : Int = 0
    public var depth   : Int = 0
    public var pixels  = [[UInt8]]()
}