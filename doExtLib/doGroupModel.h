//
//  doGroupModel.h
//  Do_Test
//
//  Created by yz on 15/9/17.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface doGroupModel : NSObject
@property(assign, nonatomic) NSInteger childCount;
@property(assign, nonatomic, getter=isOpen) BOOL open;
@end
