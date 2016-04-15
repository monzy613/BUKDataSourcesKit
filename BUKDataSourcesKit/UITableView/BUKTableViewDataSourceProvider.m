//
//  BUKTableViewDataSourceProvider.m
//  BUKDataSourcesKit
//
//  Created by Yiming Tang on 3/21/16.
//  Copyright (c) 2016 Yiming Tang. All rights reserved.
//

#import "BUKTableViewDataSourceProvider.h"
#import "BUKTableViewSection.h"
#import "BUKTableViewRow.h"
#import "BUKTableViewCellFactory.h"
#import "BUKTableViewHeaderFooterViewFactory.h"


@interface BUKTableViewDataSourceProvider ()

@property (nonatomic, readonly) NSMutableSet<NSString *> *registeredCellIdentifiers;
@property (nonatomic, readonly) NSMutableSet<NSString *> *registeredHeaderFooterViewIdentifiers;

@end


@implementation BUKTableViewDataSourceProvider

#pragma mark - Accessors

@synthesize registeredCellIdentifiers = _registeredCellIdentifiers;
@synthesize registeredHeaderFooterViewIdentifiers = _registeredHeaderFooterViewIdentifiers;

- (NSMutableSet<NSString *> *)registeredCellIdentifiers {
    if (!_registeredCellIdentifiers) {
        _registeredCellIdentifiers = [[NSMutableSet alloc] init];
    }
    return _registeredCellIdentifiers;
}


- (NSMutableSet<NSString *> *)registeredHeaderFooterViewIdentifiers {
    if (!_registeredHeaderFooterViewIdentifiers) {
        _registeredHeaderFooterViewIdentifiers = [[NSMutableSet alloc] init];
    }
    return _registeredHeaderFooterViewIdentifiers;
}


- (void)setTableView:(UITableView *)tableView {
    NSAssert([NSThread isMainThread], @"You must access BUKTableViewDataSourceProvider from the main thread.");

    _tableView.delegate = nil;
    _tableView.dataSource = nil;

    [self.registeredCellIdentifiers removeAllObjects];

    _tableView = tableView;
    [self updateTableView];
}


- (void)setSections:(NSArray<BUKTableViewSection *> *)sections {
    NSAssert([NSThread isMainThread], @"You must access BUKTableViewDataSourceProvider from the main thread.");

    _sections = sections;
    [self refresh];
}


#pragma mark - Initializer

- (instancetype)initWithTableView:(UITableView *)tableView sections:(NSArray<BUKTableViewSection *> *)sections {
    if ((self = [super init])) {
        NSAssert([NSThread isMainThread], @"You must access BUKTableViewDataSourceProvider from the main thread.");

        _automaticallyDeselectRows = YES;
        _tableView = tableView;
        _sections = sections;
        [self updateTableView];
    }
    return self;
}


- (instancetype)initWithTableView:(UITableView *)tableView {
    return [self initWithTableView:tableView sections:nil];
}


#pragma mark - Public

- (BUKTableViewSection *)sectionAtIndex:(NSInteger)index {
    if (self.sections.count <= index) {
        NSAssert1(NO, @"Invalid section index: %ld", index);
        return nil;
    }

    return self.sections[index];
}


- (BUKTableViewRow *)rowAtIndexPath:(NSIndexPath *)indexPath {
    BUKTableViewSection *section = [self sectionAtIndex:indexPath.section];
    if (section) {
        NSArray<BUKTableViewRow *> *rows = section.rows;
        if (indexPath.row < rows.count) {
            return rows[indexPath.row];
        }
    }

    NSAssert1(NO, @"Invalid index path: %@", indexPath);
    return nil;
}


#pragma mark - Private

- (void)updateTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self refresh];
}


- (void)refresh {
    [self refreshRegisteredCellIdentifiers];
    [self refreshRegisteredHeaderFooterViewIdentifiers];
    [self refreshTableSections];
}


- (void)refreshTableSections {
    [self.tableView reloadData];
}


- (void)refreshRegisteredCellIdentifiers {
    [self.sections enumerateObjectsUsingBlock:^(BUKTableViewSection * _Nonnull section, NSUInteger i, BOOL * _Nonnull stop) {
        [section.rows enumerateObjectsUsingBlock:^(BUKTableViewRow * _Nonnull row, NSUInteger j, BOOL * _Nonnull stop) {
            if (row.cellFactory) {
                NSString *cellIdentifier = [row.cellFactory reuseIdentifierForRow:row atIndexPath:[NSIndexPath indexPathForRow:j inSection:i]];
                if (![self.registeredCellIdentifiers containsObject:cellIdentifier]) {
                    Class cellClass = [row.cellFactory cellClassForRow:row atIndexPath:[NSIndexPath indexPathForRow:j inSection:i]];
                    [self.tableView registerClass:cellClass forCellReuseIdentifier:cellIdentifier];
                    [self.registeredCellIdentifiers addObject:cellIdentifier];
                }
            }
        }];
    }];
}


- (void)refreshRegisteredHeaderFooterViewIdentifiers {
    [self.sections enumerateObjectsUsingBlock:^(BUKTableViewSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop) {
        [self registerHeaderFooterViewIfNecessary:section.headerViewFactory section:section index:idx];
        [self registerHeaderFooterViewIfNecessary:section.footerViewFactory section:section index:idx];
        [self registerHeaderFooterViewIfNecessary:self.headerViewFactory section:section index:idx];
        [self registerHeaderFooterViewIfNecessary:self.footerViewFactory section:section index:idx];
    }];
}


- (void)registerHeaderFooterViewIfNecessary:(id<BUKTableViewHeaderFooterViewFactoryProtocol>)viewFactory section:(BUKTableViewSection *)section index:(NSInteger)index {
    if (!viewFactory) {
        return;
    }

    NSString *reuseIdentifier = [viewFactory reuseIdentifierForSection:section atIndex:index];
    if (!reuseIdentifier || [self.registeredHeaderFooterViewIdentifiers containsObject:reuseIdentifier]) {
        return;
    }

    Class viewClass = [viewFactory headerFooterViewClassForSection:section atIndex:index];
    NSAssert1([viewClass isSubclassOfClass:[UITableViewHeaderFooterView class]], @"View class: %@ isn't subclass of UITableViewHeaderFooterView", NSStringFromClass(viewClass));
    [self.tableView registerClass:viewClass forHeaderFooterViewReuseIdentifier:reuseIdentifier];
}


- (id<BUKTableViewHeaderFooterViewFactoryProtocol>)headerViewFactoryForSection:(BUKTableViewSection *)section {
    if (section.headerViewFactory) {
        return section.headerViewFactory;
    }

    return self.headerViewFactory;
}


- (id<BUKTableViewHeaderFooterViewFactoryProtocol>)footerViewFactoryForSection:(BUKTableViewSection *)section {
    if (section.footerViewFactory) {
        return section.footerViewFactory;
    }

    return self.footerViewFactory;
}


- (UIView *)headerFooterViewForSection:(BUKTableViewSection *)section inTableView:(UITableView *)tableView atIndex:(NSInteger)index factory:(id<BUKTableViewHeaderFooterViewFactoryProtocol>)viewFactory {
    if (!viewFactory) {
        return nil;
    }

    NSString *reuseIdentifier = [viewFactory reuseIdentifierForSection:section atIndex:index];
    if (!reuseIdentifier) {
        return nil;
    }

    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
    if (!view) {
        Class viewClass = [viewFactory headerFooterViewClassForSection:section atIndex:index];
        NSAssert1([viewClass isSubclassOfClass:[UITableViewHeaderFooterView class]], @"View class: %@ isn't subclass of UITableViewHeaderFooterView", NSStringFromClass(viewClass));
        view = [[viewClass alloc] initWithReuseIdentifier:reuseIdentifier];
    }

    [viewFactory configureView:view withSection:section inTableView:tableView atIndex:index];
    return view;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self sectionAtIndex:section].rows.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BUKTableViewRow *row = [self rowAtIndexPath:indexPath];
    id<BUKTableViewCellFactoryProtocol> cellFactory = row.cellFactory;
    if (cellFactory) {
        NSString *reuseIdentifier = [cellFactory reuseIdentifierForRow:row atIndexPath:indexPath];
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
        [cellFactory configureCell:cell withRow:row inTableView:tableView atIndexPath:indexPath];
        return cell;
    }

    return nil;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)index {
    BUKTableViewSection *section = [self sectionAtIndex:index];
    return [section.headerViewFactory titleForSection:section atIndex:index];
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)index {
    BUKTableViewSection *section = [self sectionAtIndex:index];
    return [section.footerViewFactory titleForSection:section atIndex:index];
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.automaticallyDeselectRows) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }

    BUKTableViewRow *row = [self rowAtIndexPath:indexPath];
    if (row.selection) {
        row.selection(row, tableView, indexPath);
    }
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)index {
    BUKTableViewSection *section = [self sectionAtIndex:index];
    id<BUKTableViewHeaderFooterViewFactoryProtocol> headerViewFactory = [self headerViewFactoryForSection:section];
    return [self headerFooterViewForSection:section inTableView:tableView atIndex:index factory:headerViewFactory];
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)index {
    BUKTableViewSection *section = [self sectionAtIndex:index];
    id<BUKTableViewHeaderFooterViewFactoryProtocol> footerViewFactory = [self footerViewFactoryForSection:section];
    return [self headerFooterViewForSection:section inTableView:tableView atIndex:index factory:footerViewFactory];
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)index {
    BUKTableViewSection *section = [self sectionAtIndex:index];
    id<BUKTableViewHeaderFooterViewFactoryProtocol> headerViewFactory = [self headerViewFactoryForSection:section];
    if (!headerViewFactory) {
        return 0;
    }

    return [headerViewFactory heightForSection:section atIndex:index];
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)index {
    BUKTableViewSection *section = [self sectionAtIndex:index];
    id<BUKTableViewHeaderFooterViewFactoryProtocol> footerViewFactory = [self footerViewFactoryForSection:section];
    if (!footerViewFactory) {
        return 0;
    }

    return [footerViewFactory heightForSection:section atIndex:index];
}

@end
