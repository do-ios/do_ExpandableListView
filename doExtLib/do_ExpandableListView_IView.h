//
//  do_ExpandableListView_UI.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol do_ExpandableListView_IView <NSObject>

@required
//属性方法
- (void)change_childTemplate:(NSString *)newValue;
- (void)change_groupTemplate:(NSString *)newValue;
- (void)change_isShowbar:(NSString *)newValue;
- (void)change_selectedColor:(NSString *)newValue;
- (void)change_canScrollToTop:(NSString *)newValue;
- (void)change_allExpanded:(NSString *)newValue;

//同步或异步方法
- (void)bindItems:(NSArray *)parms;
- (void)collapseGroup:(NSArray *)parms;
- (void)expandGroup:(NSArray *)parms;
- (void)refreshItems:(NSArray *)parms;
- (void)scrollToPosition:(NSArray *)parms;

@end