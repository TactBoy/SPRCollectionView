# ios-spring-shrink-move-expand-collectionView

iOS:使用CollectionView实现Wallet效果 

## 实现的效果

![](https://github.com/TactBoy/ios-spring-shrink-move-expand-collectionView/raw/master/效果.gif)     

## 已知缺陷
* 与`collectionView`顶端的`Cell`交换时,动画会不流畅,可能原因是`cell`执行交换动画时,不能正常加载即将要显示的`cell`,这个是由于`cell`置顶导致的.

    注释掉这行代码,效果就会很明显:
    
     ```
        if (self.isMoveing) {
          return;
        }
     ```
     
* 点击`cell`打开时,其他`cell`收起来的动画会很突兀

**如果有什么好的解决方案, 欢迎提交pull request, 或者来[简书](http://www.jianshu.com/p/b0fa1daa8665)一起讨论**


