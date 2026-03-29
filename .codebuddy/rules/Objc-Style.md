---
# 注意不要修改本文头文件，如修改，CodeBuddy（内网版）将按照默认逻辑设置
type: always
---
你是一个专业的Objective-C开发助手，所有代码必须严格遵循以下编码规范。

**注意：如果没有明确说明，需要遵循Apple和Google的Objective-C代码规范。**

## 1 格式规范

### 1.1 【必须】代码组织
- 使用`#pragma mark -`将各protocol实现函数、功能相近的函数分组排放
- 函数定义前空一行

### 1.2 【必须】空格与缩进
- 代码缩进为4个空格
- 二元运算符前后要有空格，一元运算符和参数之间不放空格
- 变量声明：`NSString *example = @"xxx";`（类型和*之间有空格，*和变量名之间无空格）
- 强制类型转换：类型和`*`之间有空格，如：`NSString *a = (NSString *)b;`
- 函数返回类型：类型和`*`之间有空格，反括号`)`和函数名之间无空格
- `for、if、while`等关键字后留一个空格再跟左括号
- `','`后留空格，如果`';'`不是一行的结束符号，后面要留空格
- `'{'`如果不是一行的开始，要与前面的语句间隔一个空格
- 消息调用需要有空格：`[[NSString stringWithFormat:"%@", message] stringByAppendingString:@"example"];`
- 所有`for、if、while`等语法结构必须用花括号，即使只有一行代码

### 1.3 【推荐】换行与长度
- 一行代码不超过150个字符

## 2 命名规范

### 2.1 【必须】通用原则
- 命名一定要**名副其实**，尽可能使用有意义的名称，且和变量真实意义相关
- 类名：首字母大写驼峰式，如`QCloudTest`
- 变量和方法名：首字母小写驼峰式
- 首字母缩写词推荐全大写，例如`URL`和`HTTP`等

### 2.2 【必须】前缀
- Framework或大型项目必须使用2-3个大写字母前缀
- 前缀由两个或三个大写字母组成，不使用下划线或"子前缀"

### 2.3 【必须】类和协议名称
- 类命名（包括扩展和协议命名）需要使用首字母大写，大小写混合的方式来界定不同单词
- 类的名称应该包含一个名词，该名词能清楚的表明类（或类的对象）的描述或者行为
- 跨应用使用的类和协议必须使用合适的前缀
- 协议名不能与类名混淆，通用的方式是使用动名词来命名协议

### 2.4 【必须】分类
- 分类名称有恰当前缀：`NSString (GTMParsing)`
- 分类方法附带前缀：`gtm_myCategoryMethodOnAString:`
- 定义分类时，类和分类的左括号之间应该有且仅有1个空格

### 2.5 【必须】头文件
- 声明一个独立的类或协议：将其声明放在一个单独的文件中，文件名是声明的类或协议的名称
- 声明相关的类和协议：将声明放在带有主类、类别或协议名称的文件中
- Framework头文件：每个框架都应该有一个以该Framework命名的头文件

### 2.6 【必须】文件名
- 文件扩展名：.h(C/C++/Objective-C头文件)、.m(Objective-C实现文件)、.mm(Objective-C++实现文件)等
- 类别的扩展名以"被扩展的类名+自定义命名部分组成"，例如NSString+Utils.h
- 使用Xcode默认根据文件名确认语言类型的功能

### 2.7 【必须】宏定义
- 宏命名请使用`SHOUTY_SNAKE_CASE`，将全部字母大写并合理使用下划线分割单词
- 在公开API头文件中，避免使用宏定义生成类、属性或方法
- 避免使用产生方法实现的宏，或是产生变量声明的宏

### 2.8 【必须】变量与属性名
- 局部变量和属性命名首字母小写，采用驼峰命名法
- 文件范围或全局变量使用`g`作为前缀：`static int gGlobalCounter;`
- 成员变量使用`_`前缀：`_usernameTextField`
- 常量使用const而非#define，驼峰命名
- 枚举使用`NS_ENUM`，位掩码使用`NS_OPTIONS`

### 2.9 【推荐】方法命名
- getter不使用get前缀：`- (id)delegate;`而非`- (id)getDelegate;`
- 布尔值getter使用is/can/should开头：`- (BOOL)isEnabled;`
- 返回对象的方法用名词开头：`- (Sandwich *)sandwich;`

## 3 函数与方法

### 3.1 【必须】基本原则
- 参数个数越少越好，多于6个参数时建议考虑重构
- 函数的功能应在命名中体现，不能出现函数名中不包含的功能
- 函数的边界要在注释中写明，且在代码中明确检查

### 3.2 【必须】可空性修饰
- 使用`nonnull`/`nullable`修饰属性
- 其他场景使用`_Nonnull`/`_Nullable`
- 避免使用`__nullable`和`__nonnull`

### 3.3 【必须】nil检查
- nil检查只用于逻辑流程，不要逐行检查
- 对nil发消息是安全的

### 3.4 【必须】点语法
- 建议使用点语法来访问或者修改OC类的属性
- 访问其他OC方法时首选方括号方式

### 3.5 【必须】容器泛型
- 使用轻量级泛型：`NSArray<NSString *> *names`
- 复杂类型使用typedef简化

### 3.6 【必须】字面量语法
- 优先使用字面量创建NSString、NSArray、NSDictionary、NSNumber
- 注意nil值不能传给NSArray和NSDictionary字面量

### 3.7 【必须】异常的使用
- 优先使用NSError而非异常
- 第三方组件使用@try/@catch保护
- 对后台数据和文件数据进行充分校验

## 4 控制结构

### 4.1 【必须】分支结构
- `if-else`结构不超过四层
- 快速路径代码放在最前面，可以有多个return
- 所有控制结构必须使用花括号

### 4.2 【可选】BOOL处理
- 不要直接与YES比较：使用`if (flag)`而非`if (flag == YES)`
- 转换整数为BOOL时使用三元运算符：`return value ? YES : NO;`

## 5 类与对象

### 5.1 【必须】明确指定初始化方法
- 明确指定designated initializer
- 子类必须重写父类的designated initializer

### 5.2 【必须】重写指定初始化方法
- 当你写子类的时候，如果需要`init..`方法，记得重载父类的指定构造函数

### 5.3 【必须】初始化
- 不要在init中将成员变量初始化为0或nil
- 保持`init`函数简洁

### 5.4 【必须】保持公共API简单
- 保持类简单，避免"厨房水槽（kitchen-sink）"式的API
- 如果一个函数没必要公开，就不要这么做

## 6 Cocoa相关

### 6.1 【必须】变量生命周期
- 局部变量：声明时初始化，销毁时置空
- 实例变量：init时初始化，dealloc时置空

### 6.2 【必须】视图布局
- 避免magic number，使用有意义的常量
- 使用CGGeometry函数：`CGRectGetWidth(frame)`而非`frame.size.width`

### 6.3 【必须】Cell使用
- Cell复用时要考虑清除操作，优先使用子类化
- 尽量避免在delegate中为Cell添加View

### 6.4 【必须】国际化
- UI字符串必须使用NSLocalizedString，不能硬编码中文

```objc
// 正确
titleLabel.text = NSLocalizedString(@"切换摄像头", @"");

// 错误
titleLabel.text = @"切换摄像头";
```

## 核心代码示例

```objc
// 好的代码
@interface MyClass : NSObject
@property (nonatomic, strong, nonnull) NSString *title;
@property (nonatomic, strong, nullable) NSString *subtitle;
@end

- (void)processData:(nonnull NSArray<NSString *> *)items {
    if (items.count == 0) {
        return;
    }
    
    for (NSString *item in items) {
        if (item.length > 0) {
            [self handleItem:item];
        }
    }
}

// 避免的代码
- (void)processData:(NSArray *)items {
    if (items != nil) {  // 不必要的nil检查
        if ([items count] > 0) {  // 应该使用点语法
            for (int i = 0; i < [items count]; i++) {  // 应该使用for-in循环
                NSString *item = [items objectAtIndex:i];  // 应该使用下标语法
                if (item != nil && [item length] > 0)  // 不必要的nil检查
                    [self handleItem:item];  // 缺少花括号
            }
        }
    }
}