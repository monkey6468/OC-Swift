//
//  WHTopicViewController.m
//  百思不得姐
//
//  Created by 肖伟华 on 16/8/7.
//  Copyright © 2016年 XWH. All rights reserved.
//

#import "WHTopicViewController.h"
#import "WHHTTPSessionManager.h"
#import "WHTopic.h"
#import "UIImageView+WebCache.h"
#import "WHRefreshFooter.h"
#import "WHTopicCell.h"
#import "WHCommentViewController.h"

static NSString * const WHTopicCellID = @"WHTopicCell";

@interface WHTopicViewController ()
@property (strong, nonatomic) NSMutableArray<WHTopic *> *topics;
/** 用来加载下一页数据 */
@property (copy, nonatomic) NSString *maxtime;
@property (strong, nonatomic) WHHTTPSessionManager *mgr;
@end

@implementation WHTopicViewController

- (WHTopicType)type
{
    return 0;
}
- (AFHTTPSessionManager *)mgr
{
    if (!_mgr) {
        _mgr = [WHHTTPSessionManager manager];
    }
    return _mgr;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupTableView];
    [self setupRefresh];
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([WHTopicCell class]) bundle:nil] forCellReuseIdentifier:WHTopicCellID];
    
    [self setupNoti];
}
- (void)setupNoti
{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onActionTabBarButtonRepeatClick) name:WHTabBarButtonRepeatClickNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onActionTitleButtonRepeatClick) name:WHTitleButtonRepeatClickNotification object:nil];

}
- (void)setupTableView
{
    self.tableView.contentInset = UIEdgeInsetsMake(64+35, 0, 49, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    self.tableView.backgroundColor = WHColorCommonBg;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}
- (void)setupRefresh
{
    self.tableView.mj_header = [WHRefreshHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewTopics)];
    [self.tableView.mj_header beginRefreshing];
    
    self.tableView.mj_footer = [WHRefreshFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreTopics)];
}
#pragma mark - 监听
- (void)onActionTitleButtonRepeatClick
{
    [self onActionTabBarButtonRepeatClick];
}
- (void)onActionTabBarButtonRepeatClick
{
    //如果当前控制器view 不再window上，直接返回
    if (self.view.window == nil) return;
    
    //如果当前控制器view是否与window重叠，直接返回
    if (![self.view intersectsRectWithView:[UIApplication sharedApplication].keyWindow]) return;

    [self.tableView.mj_header beginRefreshing];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
#pragma mark - 数据加载
- (void)loadMoreTopics
{
    [self.mgr.tasks makeObjectsPerformSelector:@selector(cancel)];
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    param[@"a"] = @"list";
    param[@"c"] = @"data";
    param[@"type"] = @(self.type);
    param[@"maxtime"] = self.maxtime;
    
    WHWeakSelf;
    [self.mgr GET:WHCommonURL parameters:param progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        weakSelf.maxtime = responseObject[@"info"][@"maxtime"];
        [weakSelf.topics addObjectsFromArray:[WHTopic mj_objectArrayWithKeyValuesArray:responseObject[@"list"]]];
        [weakSelf.tableView reloadData];
        [weakSelf.tableView.mj_footer endRefreshing];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        WHLogFunc
        [weakSelf.tableView.mj_footer endRefreshing];
    }];
    
}
- (void)loadNewTopics
{
    [self.mgr.tasks makeObjectsPerformSelector:@selector(cancel)];
    
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    param[@"a"] = @"list";
    param[@"c"] = @"data";
    param[@"type"] = @(self.type);//10 pic 41 video
    
    WHWeakSelf;
    [self.mgr GET:WHCommonURL parameters:param progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //
        weakSelf.maxtime = responseObject[@"info"][@"maxtime"];
        
        weakSelf.topics = [WHTopic mj_objectArrayWithKeyValuesArray:responseObject[@"list"]];
        
        [weakSelf.tableView reloadData];
        [weakSelf.tableView.mj_header endRefreshing];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        WHLogFunc
        [weakSelf.tableView.mj_header endRefreshing];
    }];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.topics.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WHTopicCell *cell = [tableView dequeueReusableCellWithIdentifier:WHTopicCellID];
    cell.topic = self.topics[indexPath.row];
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.topics[indexPath.row].cellHeight;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    WHCommentViewController *vc = [[WHCommentViewController alloc]init];
    vc.topic = self.topics[indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}
@end
