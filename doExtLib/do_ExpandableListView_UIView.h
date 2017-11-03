//
//  do_ExpandableListView_View.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "do_ExpandableListView_IView.h"
#import "do_ExpandableListView_UIModel.h"
#import "doIUIModuleView.h"

@interface do_ExpandableListView_UIView : UITableView<do_ExpandableListView_IView, doIUIModuleView>
//可根据具体实现替换UIView
{
	@private
		__weak do_ExpandableListView_UIModel *_model;
}

@end
