//
//  do_ExpandableListView_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_ExpandableListView_UIView.h"

#import "doInvokeResult.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doJsonHelper.h"
#import "doTextHelper.h"
#import "doGroupModel.h"
#import "doIPage.h"
#import "doIApp.h"
#import "doISourceFS.h"
#import "doUIContainer.h"
#import "doServiceContainer.h"
#import "doIUIModuleFactory.h"
#import "doILogEngine.h"

@interface do_ExpandableListView_UIView()<UITableViewDataSource,UITableViewDelegate>

@end

@implementation do_ExpandableListView_UIView
{
    id<doIListData> _groupDataArrays;//组模板
    id<doIListData> _childDataArrays;//子模板
    
    //组多模板,子多模板
    NSMutableArray *_childTemplateArrays;
    NSMutableArray *_groupTemplateArrays;
    doUIModule *_childModule;
    doUIModule *_groupModule;
    NSMutableArray *_doGroupArray;
    UIView *_childView;
    UIView *_groupView;
    
    NSMutableDictionary *_groupHeights;
    NSMutableDictionary *_childHeights;
    
    UIColor *_selectColor;
    
    BOOL isAllExpand;
    
    BOOL _isSmooth;
    
    CGFloat estimateHeight;
    
    CGFloat estimateChildHeight;
}
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    self.backgroundColor = [UIColor clearColor];
    _childTemplateArrays = [NSMutableArray array];
    _groupTemplateArrays = [NSMutableArray array];
    _doGroupArray = [NSMutableArray array];
    
    _groupHeights = [NSMutableDictionary dictionary];
    _childHeights = [NSMutableDictionary dictionary];
    
    self.delegate = self;
    self.dataSource = self;
    self.separatorStyle = UITableViewCellSeparatorStyleNone;

    _isSmooth = YES;
    
    estimateHeight = 0;
    estimateChildHeight = 0;
}
//销毁所有的全局对象
- (void) OnDispose
{
    //自定义的全局属性,view-model(UIModel)类销毁时会递归调用<子view-model(UIModel)>的该方法，将上层的引用切断。所以如果self类有非原生扩展，需主动调用view-model(UIModel)的该方法。(App || Page)-->强引用-->view-model(UIModel)-->强引用-->view
    self.delegate = nil;
    self.dataSource = nil;
    [_childTemplateArrays removeAllObjects];
    _childTemplateArrays = nil;
    [_groupTemplateArrays removeAllObjects];
    _groupTemplateArrays = nil;
    [_doGroupArray removeAllObjects];
    _doGroupArray = nil;
    [_childView removeFromSuperview];
    _childView = nil;
    [_groupView removeFromSuperview];
    _groupView = nil;
    [_childModule Dispose];
    _childModule = nil;
    [_groupModule Dispose];
    _groupModule = nil;
    [(doModule*)_childDataArrays Dispose];
    [(doModule*)_groupDataArrays Dispose];
    [_groupHeights removeAllObjects];
    [_childHeights removeAllObjects];
    _model = nil;
}
//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改,如果添加了非原生的view需要主动调用该view的OnRedraw，递归完成布局。view(OnRedraw)<显示布局>-->调用-->view-model(UIModel)<OnRedraw>
    
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];
}

#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */
- (void)change_allExpanded:(NSString *)newValue
{
    //自己的代码实现
    isAllExpand = [newValue boolValue];
    
    [self reloadData];
}

- (void)change_canScrollToTop:(NSString *)newValue
{
    //自己的代码实现
    BOOL isScroll = [newValue boolValue];
    self.scrollsToTop = isScroll;
}

- (void)change_childTemplate:(NSString *)newValue
{
    //自己的代码实现
    NSArray *arrays = [newValue componentsSeparatedByString:@","];
    [_childTemplateArrays removeAllObjects];
    for(int i=0;i<arrays.count;i++)
    {
        NSString *modelStr = arrays[i];
        if(modelStr != nil && ![modelStr isEqualToString:@""])
        {
            //首先计算高度
            if ([self getViewFromTemplate:modelStr isGroup:NO]) {
                [_childTemplateArrays addObject:modelStr];
            }
        }
    }
}
- (void)change_groupTemplate:(NSString *)newValue
{
    //自己的代码实现
    NSArray *arrays = [newValue componentsSeparatedByString:@","];
    [_groupTemplateArrays removeAllObjects];
    for(int i=0;i<arrays.count;i++)
    {
        NSString *modelStr = arrays[i];
        if(modelStr != nil && ![modelStr isEqualToString:@""])
        {
            if ([self getViewFromTemplate:modelStr isGroup:YES]) {
                [_groupTemplateArrays addObject:modelStr];
            }
        }
    }
}
- (void)change_isShowbar:(NSString *)newValue
{
    //自己的代码实现
    self.showsVerticalScrollIndicator = [[doTextHelper alloc] StrToBool:newValue :NO];
}
- (void)change_selectedColor:(NSString *)newValue
{
    //自己的代码实现
    UIColor *defulatCol = [doUIModuleHelper GetColorFromString:[_model GetProperty:@"selectedColor"].DefaultValue :[UIColor clearColor]];
    _selectColor = [doUIModuleHelper GetColorFromString:newValue :defulatCol];
}

#pragma mark -
#pragma mark - 同步异步方法的实现
//同步
- (void)scrollToPosition:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    //自己的代码实现
    int groupIndex = [doJsonHelper GetOneInteger:_dictParas :@"groupIndex" :0];
    @try {
        if (groupIndex >= _doGroupArray.count) {
            NSException *exc = [NSException exceptionWithName:@"ExpandableListView" reason:@"groupIndex 越界" userInfo:nil];
            [exc raise];
        }
        doGroupModel *doModel = [_doGroupArray objectAtIndex:groupIndex];
        if (!doModel.isOpen) {
            doModel.open = YES;
            NSIndexSet *indexset = [NSIndexSet indexSetWithIndex:groupIndex];
            [self reloadSections:indexset withRowAnimation:UITableViewRowAnimationNone];
        }
        NSInteger childIndex = [doJsonHelper GetOneInteger:_dictParas :@"childIndex" :0];
        _isSmooth = [doJsonHelper GetOneBoolean:_dictParas :@"isSmooth" :NO];
        
        NSInteger row = [doModel childCount];
        if (row>0) {
            if (childIndex >= row) {
                childIndex = row-1;
            }else if (childIndex < 0){
                childIndex = 0;
            }
        }else
            childIndex = NSNotFound;
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:childIndex inSection:groupIndex];
        [self scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:_isSmooth];
        doInvokeResult *invokeResult = [[doInvokeResult alloc]init];
        [invokeResult SetResultInteger:(int)indexPath.section];
        [self fireEvent:@"groupExpand" invokeResult:invokeResult];

    }
    @catch (NSException *exception) {
        [[doServiceContainer Instance].LogEngine WriteError:exception :@"下标越界"];
        doInvokeResult* _result = [[doInvokeResult alloc]init];
        [_result SetException:exception];
    }
}

- (void)bindItems:(NSArray *)parms
{
    NSDictionary * _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine= [parms objectAtIndex:1];
    NSString *groupAddress = [doJsonHelper GetOneText: _dictParas :@"groupData": nil];
    NSString *childAddress = [doJsonHelper GetOneText: _dictParas :@"childData": nil];
    id groupModule = [doScriptEngineHelper ParseMultitonModule:_scriptEngine :groupAddress];
    id childModule = [doScriptEngineHelper ParseMultitonModule:_scriptEngine :childAddress];
    @try {
        if (!groupModule || !childModule)
        {
            [NSException raise:@"doExpandableListView" format:@"Data参数无效！",nil];
        }
    }
    @catch (NSException *exception) {
        [[doServiceContainer Instance].LogEngine WriteError:exception :exception.description];
        doInvokeResult* _result = [[doInvokeResult alloc]init];
        [_result SetException:exception];
    }
    if([groupModule conformsToProtocol:@protocol(doIListData)])
    {
        if(_groupDataArrays!= groupModule)
            _groupDataArrays = groupModule;
    }
    if ([childModule conformsToProtocol:@protocol(doIListData)]) {
        if (_childDataArrays != childModule) {
            _childDataArrays = childModule;
        }
    }
    [_doGroupArray removeAllObjects];
    for (int i = 0; i < [_groupDataArrays GetCount]; i++) {
        if (i >= [_childDataArrays GetCount]) {//模板不匹配处理
            doGroupModel *tmpModel = [[doGroupModel alloc]init];
            tmpModel.childCount = 0;
            tmpModel.open = NO;
            [_doGroupArray addObject:tmpModel];
        }
        else
        {
            NSArray *childArray = [_childDataArrays GetData:i];
            doGroupModel *tmpModel = [[doGroupModel alloc]init];
            tmpModel.childCount = childArray.count;
            tmpModel.open = NO;
            [_doGroupArray addObject:tmpModel];
        }
        [self tableView:self getHeightForHeaderView:i];
    }
    [_doGroupArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        doGroupModel *doModel = (doGroupModel *)obj;
        doModel.open = isAllExpand;
    }];
    [self reloadData];
}
- (void)collapseGroup:(NSArray *)parms
{
    //参数字典_dictParas
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    NSArray *indexs = [doJsonHelper GetOneArray:_dictParas :@"indexs"];
    CGFloat maxIndexs = [[indexs lastObject] floatValue];
    //取最后一个值如果大于或等于group数组个数则表示输入的indexs已越界
    if (maxIndexs >= _doGroupArray.count) {
        return;
    } else {
        NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc]init];
        for (NSNumber *index in indexs) {
            doGroupModel *doModel = [_doGroupArray objectAtIndex:index.intValue];
            doModel.open = NO;
            [indexSet addIndex:index.integerValue];
        }
        // 刷新数据
        [UIView setAnimationsEnabled:NO];
        [self beginUpdates];
        [self reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
        [self endUpdates];
        [UIView setAnimationsEnabled:YES];
        //触发事件
        for (NSNumber *index in indexs) {
            doInvokeResult *invokeResult = [parms objectAtIndex:2];
            [invokeResult SetResultInteger:index.intValue];
            [self fireEvent:@"groupCollapse" invokeResult:invokeResult];
        }
    }
}
- (void)expandGroup:(NSArray *)parms
{
    //参数字典_dictParas
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    NSArray *indexs = [doJsonHelper GetOneArray:_dictParas :@"indexs"];
    CGFloat maxIndexs = [[indexs lastObject] floatValue];
    
    //取最后一个值如果大于或等于group数组个数则表示输入的indexs已越界
    if (maxIndexs >= _doGroupArray.count) {
        return;
    } else {
        NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc]init];
        for (NSNumber *index in indexs) {
            doGroupModel *doModel = [_doGroupArray objectAtIndex:index.intValue];
            doModel.open = YES;
            [indexSet addIndex:index.integerValue];
        }
        //刷新数据
        
        [UIView setAnimationsEnabled:NO];
        [self beginUpdates];
        [self reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
        [self endUpdates];
        [UIView setAnimationsEnabled:YES];
        
        //触发事件
        for (NSNumber *index in indexs) {
            doInvokeResult *invokeResult = [parms objectAtIndex:2];
            [invokeResult SetResultInteger:index.intValue];
            [self fireEvent:@"groupExpand" invokeResult:invokeResult];
        }
    }
}
- (void)refreshItems:(NSArray *)parms
{
    [_doGroupArray removeAllObjects];
    for (int i = 0; i < [_groupDataArrays GetCount]; i++) {
        NSArray *childArray = [_childDataArrays GetData:i];
        doGroupModel *tmpModel = [[doGroupModel alloc]init];
        tmpModel.childCount = childArray.count;
        if (!isAllExpand || isAllExpand == NO) {
            tmpModel.open = NO;
        } else {
            tmpModel.open = YES;
        }
        [_doGroupArray addObject:tmpModel];
        [self tableView:self getHeightForHeaderView:i];
    }
    NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc]init];
    for (NSUInteger section = 0;section<self.numberOfSections;section++) {
        [indexSet addIndex:section];
    }
    [UIView setAnimationsEnabled:NO];
    [self beginUpdates];
    [self reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
    [self endUpdates];
    [UIView setAnimationsEnabled:YES];

}

- (void)refreshSpecifiedItems:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    NSArray *reloadSections = [doJsonHelper GetOneArray:_dictParas :@"groupIndexes"];
    if (reloadSections.count == 0 || reloadSections == nil){ // groupIndexes 不传或者 传递[] 则默认刷新所有数据
        [self refreshItems:nil];
        return;
    }
    NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc]init];
    for (NSNumber *section in reloadSections) {
        if (section.integerValue > ([_groupDataArrays GetCount] - 1)|| section.integerValue < 0){ // 该数值越界，不予处理
            [[doServiceContainer Instance].LogEngine WriteError:nil :[NSString stringWithFormat:@"groupIndexes参数中 %d 越界",section.intValue]];
            continue;
        }
        
        NSArray *childArray = [_childDataArrays GetData:section.intValue];
        ((doGroupModel*)_doGroupArray[section.intValue]).childCount = childArray.count;
        [self tableView:self getHeightForHeaderView:section.integerValue];
        [indexSet addIndex:section.unsignedIntegerValue];
    }
    [UIView setAnimationsEnabled:NO];
    [self beginUpdates];
    [self reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
    [self endUpdates];
    [UIView setAnimationsEnabled:YES];
    
}

#pragma mark - 私有方法
-(BOOL)getViewFromTemplate:(NSString *)newValue isGroup:(BOOL)group
{
    id<doIPage> pageModel = _model.CurrentPage;
    doSourceFile *sourceFile = [pageModel.CurrentApp.SourceFS GetSourceByFileName:newValue];
    
    if ([newValue hasSuffix:@"/"]) {
        return NO;
    }
    
    if(!sourceFile){
        NSString *reason = [NSString stringWithFormat:@"模板不存在 %@",newValue];
        NSException *e = [NSException exceptionWithName:@"异常" reason:reason userInfo:nil];
        [[doServiceContainer Instance].LogEngine WriteError:e :e.reason];
        doInvokeResult* _result = [[doInvokeResult alloc]init];
        [_result SetException:e];
        return NO;
    }
    return YES;
}
- (void)groupClicked:(UIButton *)recognizer
{
    int groupIndex = (int)recognizer.tag;
    doInvokeResult *invokeResult = [[doInvokeResult alloc]init];
    [invokeResult SetResultInteger:groupIndex];
    doGroupModel *doModel = [_doGroupArray objectAtIndex:groupIndex];
    if (doModel.isOpen) {
        [self fireEvent:@"groupCollapse" invokeResult:invokeResult];
    }
    else
    {
        [self fireEvent:@"groupExpand" invokeResult:invokeResult];
    }
    doModel.open = !doModel.isOpen;
    [self fireEvent:@"groupTouch" invokeResult:invokeResult];
    
    NSIndexSet *indexSet = [[NSIndexSet alloc]initWithIndex:recognizer.tag];
    [self reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
}
//触发事件
- (void)fireEvent:(NSString *)eventName invokeResult:(doInvokeResult *)result
{
    [_model.EventCenter FireEvent:eventName :result];
}
-(UIImage *)createImageWithColor:(UIColor *)color
{
    CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);

    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return theImage;
    
}
#pragma mark - ScrollView 代理方法
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.contentSize.height<=0) {
        return;
    }
    if (!_isSmooth) {
        return;
    }
    NSMutableDictionary *node = [NSMutableDictionary dictionaryWithCapacity:1];
    [node setObject:@(scrollView.contentOffset.y / _model.YZoom) forKey:@"offset"];
    doInvokeResult *invokeResult = [[doInvokeResult alloc]init];
    [invokeResult SetResultNode:node];
    [_model.EventCenter FireEvent:@"scroll" :invokeResult];
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    _isSmooth = YES;
}
#pragma mark - TableView代理方法
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSNumber *h = [_groupHeights objectForKey:@(section)];
    if (!h) {
        [self tableView:tableView getHeightForHeaderView:section];
        h = [_groupHeights objectForKey:@(section)];
    }
    if ([h floatValue]<=0) {
        return .1;
    }
    return [h floatValue];
}
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    NSNumber *h = [_groupHeights objectForKey:@(section)];
    if (!h) {
        h = @(estimateHeight?estimateHeight:100);
    }
    if ([h floatValue]<=0) {
        return .1;
    }
    return [h floatValue];
}
- (UIView *)tableView:(UITableView *)tableView getHeightForHeaderView:(NSInteger)section
{
    id jsonValue = [NSDictionary dictionary];
    if ([_groupDataArrays GetCount] > 0) {
        jsonValue = [_groupDataArrays GetData:(int)section];
    }
    NSDictionary *dataNode = [doJsonHelper GetNode:jsonValue];
    int groupIndex = [doJsonHelper GetOneInteger:dataNode :@"template" :0];
    
    if (groupIndex < 0 || groupIndex >= _groupTemplateArrays.count) {
        if (_groupTemplateArrays.count>0) {
            groupIndex = 0;
        }else{
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataNode options:NSJSONWritingPrettyPrinted error:nil];
            [[doServiceContainer Instance].LogEngine WriteError:nil : [NSString stringWithFormat:@"group模板数据:%@ 对应的group模板为空或者模板数据中template > group模板总数",[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]]];
            return [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"do_ExpandListView_emptyHeaderFooterView"];
        }
    }
    
    static NSString *groupIndentify = @"";
    if (_groupTemplateArrays.count > 0) {
        groupIndentify = [_groupTemplateArrays objectAtIndex:groupIndex];
    }
    UITableViewHeaderFooterView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:groupIndentify];
    doUIModule *groupMode;
    if (!headerView) {
        headerView = [[UITableViewHeaderFooterView alloc]initWithReuseIdentifier:groupIndentify];
        @try {
            groupMode = [[doServiceContainer Instance].UIModuleFactory CreateUIModuleBySourceFile:groupIndentify :_model.CurrentPage :YES];
            [groupMode.CurrentUIModuleView OnRedraw];
            UIView *inserView = (UIView *)groupMode.CurrentUIModuleView;
            UIButton *tipBtn = [[UIButton alloc]initWithFrame:inserView.frame];
            [tipBtn setBackgroundImage:[self createImageWithColor:_selectColor] forState:UIControlStateHighlighted];
            [tipBtn addTarget:self action:@selector(groupClicked:) forControlEvents:UIControlEventTouchUpInside];
            headerView.backgroundView = tipBtn;//需要设置，不然影响背景
            _groupView = inserView;
            [headerView.contentView addSubview:tipBtn];
            [headerView.contentView addSubview:inserView];
        }
        @catch (NSException *exception) {
            
        }
    }
    else
    {
        groupMode = [(id<doIUIModuleView>)[headerView.contentView.subviews objectAtIndex:1]GetModel];
    }
    UIButton *btnc = headerView.contentView.subviews[0];
    btnc.tag = section;
    id jsonData =[_groupDataArrays GetData:(int)section];
    [groupMode SetModelData:jsonData];
    [groupMode.CurrentUIModuleView OnRedraw];
    
    
    UIView *v = (UIView*)groupMode.CurrentUIModuleView;
    CGRect r = v.frame;
    CGFloat h = r.size.height;
    if (h>0.0) {
        estimateHeight = h;
        [_groupHeights setObject:@(h) forKey:@(section)];
    }
    return headerView;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [self tableView:tableView getHeightForHeaderView:section];
}
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    [((UITableViewHeaderFooterView *)view).contentView setBackgroundColor:[UIColor clearColor]];
}
- (void)changeSelectColor:(UITableViewCell *)cell
{
    if (!_selectColor) {
        return;
    }
    const CGFloat *components = CGColorGetComponents(_selectColor.CGColor);
    if (components[3] == 0) {
        return;
    }
    cell.backgroundColor = _selectColor;
    [UIView animateWithDuration:0.1 animations:^{
        cell.backgroundColor = [UIColor clearColor];
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSMutableDictionary *node = [NSMutableDictionary dictionary];
    [node setObject:@(indexPath.section) forKey:@"groupIndex"];
    [node setObject:@(indexPath.row) forKey:@"childIndex"];
    doInvokeResult *invokeResult = [[doInvokeResult alloc]init];
    [invokeResult SetResultNode:node];
    [_model.EventCenter FireEvent:@"childTouch" :invokeResult];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    [self changeSelectColor:cell];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSNumber *h = [_childHeights objectForKey:@(indexPath.row)];
//    if (!h) {
//        [self tableView:tableView getHeightForRowAtIndexPath:indexPath];
//        h = [_childHeights objectForKey:@(indexPath.row)];
//    }
    
    NSNumber * h = nil;
    [self tableView:tableView getHeightForRowAtIndexPath:indexPath];
    h = [_childHeights objectForKey:@(indexPath.row)];
    
    if ([h floatValue]<=1) {
        return 100;
    }
    return [h floatValue];
}
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *h = [_childHeights objectForKey:@(indexPath.section)];
    if (!h) {
        h = @(estimateChildHeight?estimateChildHeight:100);
    }
    if ([h floatValue]<=1) {
        return 100;
    }
    return [h floatValue];
}

#pragma mark - TableView数据源方法
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_groupDataArrays GetCount];

}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section >= _doGroupArray.count) {
        return 0;
    }
    doGroupModel *doModel = [_doGroupArray objectAtIndex:section];
    if (doModel.isOpen) {
        return doModel.childCount;
    }
    else
    {
        return 0;
    }

}
- (UITableViewCell *)tableView:(UITableView *)tableView getHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *jsonValue = [NSArray array];
    if ([_childDataArrays GetCount] > 0) {
        jsonValue = [_childDataArrays GetData:(int)indexPath.section];
    }
    //    NSArray *dataArray = [doJsonHelper GetArray:jsonValue];
    NSDictionary *dataNode = [jsonValue objectAtIndex:indexPath.row];
    int childIndex = [doJsonHelper GetOneInteger:dataNode :@"template" :0];
    
    if (childIndex < 0 || childIndex >= _childTemplateArrays.count) {
        if (_childTemplateArrays.count > 0) {
            childIndex = 0;
        }else{
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataNode options:NSJSONWritingPrettyPrinted error:nil];
            [[doServiceContainer Instance].LogEngine WriteError:nil : [NSString stringWithFormat:@"child模板数据:%@ 对应的child模板为空或者template>子模板总数",[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]]];
            return [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"do_ExpandListView_emptyCell"];
        }
    }
    
    static NSString *childIndentify = @"expandListCell";
    if (_groupTemplateArrays.count > 0) {
        childIndentify = [_childTemplateArrays objectAtIndex:childIndex];
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:childIndentify];
    doUIModule *childCellMode;
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:childIndentify];
        @try {
            childCellMode = [[doServiceContainer Instance].UIModuleFactory CreateUIModuleBySourceFile:childIndentify :_model.CurrentPage :YES];
            UIView *inserView = (UIView *)childCellMode.CurrentUIModuleView;
            [cell.contentView addSubview:inserView];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            CGRect r = inserView.frame;
            CGFloat h = r.size.height;
            if (h<2) {
                h=2;
            }
            r.size.height += 1;
            inserView.frame = r;
            cell.backgroundColor = [UIColor clearColor];
        }
        @catch (NSException *exception) {
            [[doServiceContainer Instance].LogEngine WriteError:exception : @"模板不存在"];
            doInvokeResult* _result = [[doInvokeResult alloc]init];
            [_result SetException:exception];
            
            return cell;
        }
    }
    else
    {
        if (cell.contentView.subviews.count>0) {
            childCellMode = [(id<doIUIModuleView>)[cell.contentView.subviews objectAtIndex:0]GetModel];
        }
    }
    if (cell.contentView.subviews.count>0) {
        NSArray * cellArrays =[_childDataArrays GetData:(int)indexPath.section];
        if (cellArrays.count>0) {
            id jsonData = [cellArrays objectAtIndex:indexPath.row];
            [childCellMode SetModelData:jsonData];
            [childCellMode.CurrentUIModuleView OnRedraw];
            
            UIView *cellView = (UIView*)childCellMode.CurrentUIModuleView;
            CGRect r = cellView.frame;
            CGFloat h = r.size.height;
            if (h>0) {
                estimateChildHeight = h;
                [_childHeights setObject:@(h) forKey:@(indexPath.row)];
            }
        }
    }
    
    return cell;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self tableView:tableView getHeightForRowAtIndexPath:indexPath];
}

#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}

@end
