//
//  FeedViewController.swift
//  Course2FinalTask
//
//  Created by Игорь on 15/09/2019.
//  Copyright © 2019 e-Legion. All rights reserved.
//
import UIKit
import CoreData

var posts: Posts?

class FeedTableViewController:  UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navigationBar: UINavigationItem!
    
    var selectedIndex = 0
    
    let spinner = UIActivityIndicatorView()
    
    var refreshControll: UIRefreshControl = {
        let rfControll = UIRefreshControl()
        rfControll.addTarget(self, action: #selector(refresh(sender:)),for: .valueChanged)
        return rfControll
    }()
    
    var savedPostsMap = [Int:Bool]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(FeedViewCell.self, forCellReuseIdentifier: "kekCellid")
        
        tableView.separatorStyle = .none
        tableView.refreshControl = refreshControll
        
        tableView.delegate = self
        tableView.dataSource = self
        
        if !isOfflineMode {
            dataManager.deleteAllEntities(entityName: "PostModel")
            getPostsInTableViewController()
        } else {
            posts = Posts()
        }
        viewConfiger()
        
        if isOfflineMode {
            fetchData(predicate: nil)
        }
    }
    
    @objc private func refresh(sender: UIRefreshControl) {
        getPostsInTableViewController()
        tableView.reloadData()
        sender.endRefreshing()
    }
    
    func getPostsInTableViewController() {
        let group = DispatchGroup()
        DispatchQueue.global().async(group: group) {
            group.enter()
            getPostsForFeed(token: token) {
                result in
                switch result {
                case .success(let arrayOfPosts):
                    posts = arrayOfPosts
                    
                    let context = dataManager.getConetxt()
                    for post in arrayOfPosts.posts {
                        if self.savedPostsMap[post.id!] == nil {
                            self.savedPostsMap[post.id!] = true
                            
                            let postForCoreData = dataManager.createObject(from: PostModel.self)
                            postForCoreData.authorAvatar = post.authorAvatar?.absoluteString
                            postForCoreData.authorId = Int64(post.authorId!)
                            postForCoreData.authorUsername = post.authorUsername
                            postForCoreData.createdTime = post.createdTime!
                            postForCoreData.currentUserLikesThisPost = post.currentUserLikesThisPost ?? false
                            postForCoreData.descriptionOfPost = post.description
                            postForCoreData.image = post.image?.absoluteString
                            postForCoreData.id = Int64(post.id!)
                            postForCoreData.likedByCount = Int64(post.likedByCount!)
                            
                            dataManager.save(context: context)
                        }
                    }
                case .fail(let error):
                    print(error)
                case .badResponse(let res):
                    print(res)
                }
                group.leave()
            }
        }
        group.wait()
    }
    
    func fetchData(predicate: NSCompoundPredicate?) {
        let fetchedPosts = dataManager.fetchData(for: PostModel.self)
        posts = Posts(coreDataPosts: fetchedPosts)
    }
    

    func viewConfiger() {
        view.bringSubviewToFront(loadingSpinner)
        loadingSpinner.style = .whiteLarge
        loadingSpinner.backgroundColor = (UIColor (white: 0.3, alpha: 0.8))
        loadingSpinner.layer.cornerRadius = 10
        loadingSpinner.frame = CGRect(x: 0.0, y: 0.0, width: 60, height: 60)
        loadingSpinner.center = (self.navigationController?.view.center)!
        loadingSpinner.isHidden = true
        
        navigationBar.title = "Feed"
        tableView.estimatedRowHeight = 300
        tableView.reloadData()
        tableView.setNeedsLayout()
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts!.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: "FeedViewCell")) as! FeedViewCell
        
        cell.setCell(with: posts!.posts[indexPath.row], index: indexPath.row)
        cell.postImage.isUserInteractionEnabled = true
        cell.selectionStyle = .none
        
        if posts!.posts[indexPath.row].currentUserLikesThisPost! {
            cell.likeImage.tintColor = .red
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    //
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    //
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You selected cell #\(indexPath.row)!")
        selectedIndex = indexPath.row
    }
    
    func startLoading() {
        loadingSpinner.startAnimating()
    }
    
    @IBAction func LikesCoutnerPressed(_ sender: Any) {
        
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.main.async {
            self.loadingSpinner.isHidden = false
            self.loadingSpinner.startAnimating()
            group.leave()
        }
        
        group.notify(queue: DispatchQueue.main) {
            self.performSegue(withIdentifier: "likesPressed", sender: nil)
        }
        
        let buttonPosition = (sender as AnyObject).convert(CGPoint(), to:tableView)
        let indexPath = tableView.indexPathForRow(at:buttonPosition)
        selectedIndex = indexPath?.row ?? 0
        print("You selected cell #\(selectedIndex)!")
    }
    
    @IBAction func userNamePressed(_ sender: Any) {
        
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.main.async {
            self.loadingSpinner.isHidden = false
            self.loadingSpinner.startAnimating()
            group.leave()
        }
        
        group.notify(queue: DispatchQueue.main) {
            self.performSegue(withIdentifier: "toOtherUser2", sender: nil)
        }
        
        let buttonPosition = (sender as AnyObject).convert(CGPoint(), to:tableView)
        let indexPath = tableView.indexPathForRow(at:buttonPosition)
        selectedIndex = indexPath?.row ?? 0
        print("You selected cell #\(selectedIndex)!")
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? likeTableViewController {
            //
            let passedPostID = posts!.posts[selectedIndex].id!
            destination.postID = passedPostID
            loadingSpinner.isHidden = true
        }
        if let destination = segue.destination as? OtherUserProfileControllerViewController {
            let passedUserID = posts!.posts[selectedIndex].authorId
            destination.userID = passedUserID
            loadingSpinner.isHidden = true
            
        }
    }
}
