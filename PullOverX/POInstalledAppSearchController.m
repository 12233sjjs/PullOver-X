#import "POInstalledAppSearchController.h"
#import <objc/message.h>

#import "POApplicationHelper.h"

@interface LSApplicationProxy : NSObject
@property (nonatomic, readonly) NSString *applicationIdentifier;
@property (nonatomic, readonly) NSString *localizedName;
@property (nonatomic, readonly) NSString *applicationType;
@property (nonatomic, readonly) BOOL isPlaceholder;
- (BOOL)respondsToSelector:(SEL)aSelector;
@end

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (NSArray<LSApplicationProxy *> *)allApplications;
@end

@interface POInstalledAppSearchController () <UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating>
@property (nonatomic, copy) POInstalledAppSearchSelection selection;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, NSString *> *> *apps;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, NSString *> *> *filteredApps;
@property (nonatomic, assign) NSUInteger loadGeneration;
@property (nonatomic, assign) BOOL isSearching;
@end

@implementation POInstalledAppSearchController

- (instancetype)initWithSelection:(POInstalledAppSearchSelection)selection {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _selection = [selection copy];
        _apps = @[];
        _filteredApps = @[];
        self.modalPresentationStyle = UIModalPresentationFormSheet;
        self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    }
    return self;
}

- (void)loadView {
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.rowHeight = 58.0;
    self.tableView = tableView;
    self.view = tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Search Apps";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"App name or bundle identifier";
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.definesPresentationContext = YES;

    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                            target:self
                                                                            action:@selector(cancelSearch)];
    self.navigationItem.leftBarButtonItem = cancel;
    [self loadInstalledApps];
}

- (void)loadInstalledApps {
    NSUInteger generation = ++self.loadGeneration;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableArray<NSDictionary<NSString *, NSString *> *> *apps = [NSMutableArray array];
        @try {
            Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
            SEL defaultWorkspace = NSSelectorFromString(@"defaultWorkspace");
            id workspace = [workspaceClass respondsToSelector:defaultWorkspace]
                ? ((id (*)(id, SEL))objc_msgSend)(workspaceClass, defaultWorkspace) : nil;
            SEL allApplications = NSSelectorFromString(@"allApplications");
            id proxies = [workspace respondsToSelector:allApplications]
                ? ((id (*)(id, SEL))objc_msgSend)(workspace, allApplications) : nil;
            for (id proxy in ([proxies isKindOfClass:NSArray.class] ? proxies : @[])) {
                @try {
                    SEL identifierSelector = NSSelectorFromString(@"applicationIdentifier");
                    SEL typeSelector = NSSelectorFromString(@"applicationType");
                    SEL nameSelector = NSSelectorFromString(@"localizedName");
                    NSString *identifier = [proxy respondsToSelector:identifierSelector]
                        ? ((id (*)(id, SEL))objc_msgSend)(proxy, identifierSelector) : nil;
                    NSString *type = [proxy respondsToSelector:typeSelector]
                        ? ((id (*)(id, SEL))objc_msgSend)(proxy, typeSelector) : nil;
                    NSString *name = [proxy respondsToSelector:nameSelector]
                        ? ((id (*)(id, SEL))objc_msgSend)(proxy, nameSelector) : nil;
                    if (![identifier isKindOfClass:NSString.class] || identifier.length == 0 ||
                        ![POApplicationHelper isUserFacingApplicationBundleId:identifier] ||
                        (type.length > 0 && ![type isEqualToString:@"User"])) {
                        continue;
                    }
                    SEL hiddenSelector = NSSelectorFromString(@"isHidden");
                    if ([proxy respondsToSelector:hiddenSelector] &&
                        ((BOOL (*)(id, SEL))objc_msgSend)(proxy, hiddenSelector)) {
                        continue;
                    }
                    [apps addObject:@{@"id": identifier, @"name":
                        ([name isKindOfClass:NSString.class] && name.length > 0) ? name : identifier}];
                } @catch (__unused NSException *exception) {}
            }
        } @catch (__unused NSException *exception) {}
        [apps sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            NSComparisonResult result = [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
            return result == NSOrderedSame ? [a[@"id"] compare:b[@"id"]] : result;
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (generation != self.loadGeneration || !self.isViewLoaded) return;
            self.apps = apps;
            self.filteredApps = apps;
            [self.tableView reloadData];
            if (apps.count == 0) {
                self.tableView.backgroundView = [[UILabel alloc] initWithFrame:CGRectZero];
                UILabel *label = (UILabel *)self.tableView.backgroundView;
                label.text = @"No launchable apps found";
                label.textColor = UIColor.secondaryLabelColor;
                label.textAlignment = NSTextAlignmentCenter;
            }
        });
    });
}

- (void)updateSearchResultsForSearchController:(UISearchController *)controller {
    NSString *query = [controller.searchBar.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    self.isSearching = query.length > 0;
    if (query.length == 0) {
        self.filteredApps = self.apps;
    } else {
        NSString *needle = query.lowercaseString;
        self.filteredApps = [self.apps filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *app, NSDictionary *bindings) {
            (void)bindings;
            return [app[@"name"] rangeOfString:needle options:NSCaseInsensitiveSearch].location != NSNotFound ||
                [app[@"id"] rangeOfString:needle options:NSCaseInsensitiveSearch].location != NSNotFound;
        }]];
    }
    [self.tableView reloadData];
}

- (void)focusSearch { [self.searchController.searchBar becomeFirstResponder]; }
- (void)cancelSearch { [self dismissViewControllerAnimated:YES completion:nil]; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.filteredApps.count; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"POInstalledAppSearchCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    NSDictionary *app = self.filteredApps[indexPath.row];
    NSString *bundleId = app[@"id"];
    cell.textLabel.text = app[@"name"];
    cell.detailTextLabel.text = bundleId;
    cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
    cell.imageView.image = [POApplicationHelper imageForBundleId:bundleId];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *bundleId = self.filteredApps[indexPath.row][@"id"];
    POInstalledAppSearchSelection selection = self.selection;
    [self dismissViewControllerAnimated:YES completion:^{ if (selection) selection(bundleId); }];
}

@end
