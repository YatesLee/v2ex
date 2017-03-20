//
//  TopicDetailsViewController.swift
//  V2EX
//
//  Created by wgh on 2017/3/7.
//  Copyright © 2017年 yitop. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class TopicDetailsViewController: UITableViewController {
    @IBOutlet weak var headerView: TopicDetailsHeaderView!

    var viewModel: TopicDetailsViewModel?
    fileprivate lazy var dataSource = RxTableViewSectionedAnimatedDataSource<TopicDetailsSection>()
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        tableView.dataSource = nil
        
        guard let viewModel = viewModel else { return }
        
        headerView.topic = viewModel.topic
        
        dataSource.configureCell = {(ds, tv, indexPath, item) in
            switch ds[indexPath.section].type {
            case .more:
                let cell: LoadMoreCommentCell = tv.dequeueReusableCell()
                return cell
            case .data:
                let cell: TopicDetailsCommentCell = tv.dequeueReusableCell()
                cell.comment = item
                return cell
            }
        }
        
        dataSource.titleForHeaderInSection = {[weak viewModel] (ds, sectionIndex) in
            if sectionIndex == 0, let viewModel = viewModel {
                return ds[sectionIndex].comments.isEmpty ? "目前尚无回复" : viewModel.countTime.value
            }
            return nil
        }
      
        viewModel.updateTopic.asObservable().bindTo(headerView.rx.topic).addDisposableTo(disposeBag)
        viewModel.content.asObservable().bindTo(headerView.rx.htmlString).addDisposableTo(disposeBag)
        viewModel.sections.asObservable().bindTo(tableView.rx.items(dataSource: dataSource)).addDisposableTo(disposeBag)
        
        headerView.heightUpdate.asObservable().subscribe(onNext: {[weak self] isUpdate in
            if let `self` = self, isUpdate {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
        }).addDisposableTo(disposeBag)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension TopicDetailsViewController {
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 40 : 0
    }
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if section == 0 && view is UITableViewHeaderFooterView {
            let header = view as! UITableViewHeaderFooterView
            header.textLabel?.font = UIFont.systemFont(ofSize: 13)
            header.textLabel?.textColor = #colorLiteral(red: 0.2509803922, green: 0.2509803922, blue: 0.2509803922, alpha: 1)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch dataSource[indexPath.section].type {
        case .more:
            if let cell = tableView.cellForRow(at: indexPath) as? LoadMoreCommentCell {
                viewModel?.loadMoreActivityIndicator.asObservable().bindTo(cell.activityIndicatorView.rx.isAnimating).addDisposableTo(disposeBag)
            }
            viewModel?.fetchMoreComments()
        case .data:
            print("点击评论....")
        }
    }
}