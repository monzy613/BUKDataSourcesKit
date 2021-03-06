//
//  BUKCollectionViewSection.m
//  BUKDataSourcesKit
//
//  Created by Yiming Tang on 3/21/16.
//  Copyright (c) 2016 Yiming Tang. All rights reserved.
//

#import "BUKCollectionViewSection.h"


@implementation BUKCollectionViewSection

#pragma mark - Class Methods

+ (instancetype)section {
    return [[self alloc] init];
}


+ (instancetype)sectionWithItems:(NSArray<__kindof BUKCollectionViewItem *> *)items {
    return [[self alloc] initWithItems:items];
}


+ (instancetype)sectionWithItems:(NSArray<__kindof BUKCollectionViewItem *> *)items cellFactory:(id<BUKCollectionViewCellFactoryProtocol>)cellFactory supplementaryViewFactory:(id<BUKCollectionViewSupplementaryViewFactoryProtocol>)supplementaryViewFactory {
    return [[self alloc] initWithItems:items cellFactory:cellFactory supplementaryViewFactory:supplementaryViewFactory];
}


#pragma mark - Initializer

- (instancetype)initWithItems:(NSArray<__kindof BUKCollectionViewItem *> *)items cellFactory:(id<BUKCollectionViewCellFactoryProtocol>)cellFactory supplementaryViewFactory:(id<BUKCollectionViewSupplementaryViewFactoryProtocol>)supplementaryViewFactory {
    if ((self = [super init])) {
        _items = [items copy];
        _cellFactory = cellFactory;
        _supplementaryViewFactory = supplementaryViewFactory;
    }

    return self;
}


- (instancetype)initWithItems:(NSArray<BUKCollectionViewItem *> *)items {
    return [self initWithItems:items cellFactory:nil supplementaryViewFactory:nil];
}


- (instancetype)init {
    return [self initWithItems:nil];
}


#pragma mark - Public

- (BUKCollectionViewItem *)itemAtIndex:(NSInteger)index {
    if (0 <= index && index < self.items.count) {
        return self.items[index];
    }

    NSAssert1(NO, @"Invalid index: %ld in section", (long)index);
    return nil;
}

@end
