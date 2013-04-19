import QtQuick 2.0
import QtWebKit 3.0
import QtWebKit.experimental 1.0
import "script.js" as Tab 

Item {
    width: 320 // 800
    height: 480 // 600

    // TODO: move New_Tab button out of ListModel
    property string currentTab: "new_tab"
    property variant drawerWIDTH: 280 
    property variant drawerHEIGHT: 40 
    property variant drawerMARGIN: 10 

    function openNewTab(pageid, url) {
        console.log("openNewTab: "+ pageid);
        console.log(tabListView.model.get(tabListView.currentIndex).title);
        var webView = tabView.createObject(container, { id: pageid, objectName: pageid } );
        webView.url = url; // FIXME: should use loadUrl() wrapper 

        // FIXME: should bind loading / indicator to tab icon and load progress 
        tabModel.append( { "title": "Loading..", "url": url, "favicon": "icon/favicon.png" } );
        Tab.itemMap[pageid] = webView;
        if (currentTab.match(/^page/)) // hide current tab and display the new
        Tab.itemMap[currentTab].visible = false;
        currentTab = pageid; 
        tabListView.currentIndex = tabModel.count - 1;
    }

    function switchToTab(pageid) {
        //console.log("switchToTab: "+ pageid + ", currentTab: " + currentTab);
        Tab.itemMap[currentTab].visible = false;
        currentTab = pageid;
        Tab.itemMap[currentTab].visible = true;

        // assign url to text bar
        urlText.text = Tab.itemMap[currentTab].url;
        //console.log(currentTab + ":"+ Tab.itemMap[currentTab]);

    }

    function closeTab(pageid) { } // TODO: destroy item, delete from itemMap, switch tab to previous one

    function fixUrl(url) {
        // FIXME: get rid of space 
        if (url == "") return url;
        if (url[0] == "/") { return "file://"+url; }
        //FIXME: search engine support here
        if (url.indexOf(":")<0) { return "http://"+url; }
        else { return url;}
    }

    Component {
        id: tabView
        WebView { 
            anchors.left: parent.left 
            anchors.top: parent.top
            anchors.fill: parent

            z: 2 // for drawer open/close control  
            anchors.topMargin: 40 // FIXME: should use navigator bar item
            experimental.userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3"

            onLoadingChanged: { 
                urlText.text = Tab.itemMap[currentTab].url;
                if (loadRequest.status == WebView.LoadSucceededStatus) {
                    // set title & favicon to listview
                    // FIXME: get page index 
                    // should binding listview title to page title & favicon 
                    tabListView.model.get( objectName.slice(4) ).title = title;

                    // FIXME: favicon doesn't display in redirect request 
                    if(icon)
                    tabModel.setProperty( objectName.slice(4), "favicon", ""+icon );
                    else tabModel.setProperty( objectName.slice(4), "favicon", "icon/favicon.png" );
                }
            }
        }
    }

    Rectangle {
        id: drawer
        anchors.left: parent.left
        anchors.top: parent.top
        width: drawerWIDTH 
        height: parent.height
        color: "#33343E" 

        ListModel {
            id: tabModel
            ListElement {
                title: "+ New Page"
                url: "http://google.com"
                favicon: "icon/favicon.png" 
            }
        }

        Component {
            id: tabDelegate
            Row {
                spacing: 10
                Rectangle {
                    width: drawerWIDTH
                    height: drawerHEIGHT //30
                    color: "transparent"
                    Image { 
                        height: 16; width: 16; source: (index==0) ? "" : model.favicon; // FIXME: new-tab icon?
                        anchors { top: parent.top; left: parent.left; margins: drawerMARGIN; } 
                    }
                    Text { 
                        text: model.title; color: "white"; 
                        anchors { top: parent.top; left: parent.left; margins: drawerMARGIN; leftMargin: drawerMARGIN+20 } 
                    }
                    MouseArea { 
                        anchors.fill: parent; 
                        onClicked: { 
                            tabListView.currentIndex = index;
                            if (index === 0) { // new tab
                                openNewTab("page"+tabModel.count, url);
                            } else {  // change tab visibility 
                                switchToTab("page"+index);
                            }
                        }
                    }
                }
            }
        }
        ListView {
            id: tabListView
            anchors.fill: parent
            model: tabModel
            delegate: tabDelegate 
            highlight: 
            
            Rectangle { width: drawerWIDTH; height: drawerHEIGHT 
                gradient: Gradient {
                    GradientStop { position: 0.1; color: "#1F1F23" }
                    GradientStop { position: 0.5; color: "#28282F" }
                    GradientStop { position: 0.8; color: "#2A2B31" }
                    GradientStop { position: 1.0; color: "#25252A" }
                
                }
            }
            highlightFollowsCurrentItem: true 
        }
    }

    Rectangle {
        id: container 
        anchors.left: parent.left 
        anchors.top: parent.top
        width: parent.width
        height: parent.height
        //color: "#E4E4E8" // light gray
        z: 1 
        radius: 3 

        Rectangle { 
            height: 40; width: parent.width; anchors.top: parent.top; anchors.left: parent.left
            radius: 3 
            gradient: Gradient { 
                GradientStop { position: 0.0; color: "#FAFAFA" }
                GradientStop { position: 0.5; color: "#E8E9EC" }
                GradientStop { position: 1.0; color: "#E2E3E7" }
            }
        }
        // Navigator Bar, should use verticalCenter: parent.verticalCenter
        // drawer button 
        Item { 
            id: drawerButton
            width: 30; height: 30; anchors { top: parent.top; left: parent.left; margins: 5 } 
            Image { source: "icon/64-List-w_-Images.png"; anchors.fill: parent; }
            MouseArea {
                anchors.fill: parent;
                onClicked: { container.state == "closed" ? container.state = "opened" : container.state = "closed"; }
            }
        }

        // TODO: back / forward button 

        Rectangle { 
            id: urlBar 
            anchors { left: drawerButton.right; top: parent.top; margins: 6 } 
            color: "white"
            height: 25 
            border { width: 1; color: "black" }
            radius: 5 
            width: parent.width - 60

            Rectangle {
                anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
                radius: 3
                // FIXME: first tab should be webview or not? 
                width: (currentTab !== "new_tab" ) ? 
                parent.width / 100 * Math.max(5, Tab.itemMap[currentTab].loadProgress) : 0
                color: "#FED164" // light yellow 
                opacity: 0.4
                visible: (currentTab !== "new_tab" ) ? Tab.itemMap[currentTab].loading : false 
            }

            TextInput { 
                id: urlText
                text: (currentTab != "new_tab") ? Tab.itemMap[currentTab].url : ""
                anchors { fill: parent; margins: 5 }
                Keys.onReturnPressed: { 
                    if (currentTab != "new_tab") { 
                        Tab.itemMap[currentTab].url = fixUrl(text) 
                    } else { // FIXME: open first page, should be done while initialize?  
                        openNewTab("page"+tabModel.count, fixUrl(text));
                    }
                    Tab.itemMap[currentTab].focus = true;
                }
                onActiveFocusChanged: { 
                    // FIXME: use State to change property  
                    if (urlText.activeFocus) { urlText.selectAll(); parent.border.color = "#2E6FFD"; parent.border.width = 2;} 
                    else { parent.border.color = "black"; parent.border.width = 1; } 
                }
            }            

            Image {
                id: stopButton
                anchors { right: urlBar.right; rightMargin: 5; verticalCenter: parent.verticalCenter}
                source: "icon/bt_browser_stop.png"
                visible: ( (currentTab != "new_tab") && Tab.itemMap[currentTab].loadProgress < 100 && !urlText.focus) ? 
                true : false
                MouseArea {
                    anchors { fill: parent; margins: -10; }
                    onClicked: { Tab.itemMap[currentTab].stop(); }
                }
            }
            Image {
                id: reloadButton
                anchors { right: urlBar.right; rightMargin: 5; verticalCenter: parent.verticalCenter}
                source: "icon/bt_browser_reload.png"
                visible: ( (currentTab != "new_tab") && Tab.itemMap[currentTab].loadProgress == 100 && !urlText.focus ) ? 
                true : false 
                MouseArea {
                    anchors { fill: parent; margins: -10; }
                    onClicked: { Tab.itemMap[currentTab].reload(); }
                }
            }
            Image {
                id: clearButton
                anchors { right: urlBar.right; rightMargin: 5; verticalCenter: parent.verticalCenter}
                source: "icon/bt_browser_clear.png"
                visible: urlText.focus
                MouseArea {
                    anchors { fill: parent; margins: -10; }
                    onClicked: { urlText.text = ""; }
                }
            }
        }

        MouseArea { 
            z: (container.state == "opened") ? 3 : 1
            anchors.fill: parent
            anchors.topMargin: 40 
            onClicked: { container.state == "closed" ? container.state = "opened" : container.state = "closed"; }
        }
        states: [
            State{
                name: "opened"
                PropertyChanges { target: container; anchors.leftMargin: drawerWIDTH }
            },
            State {
                name: "closed"
                PropertyChanges { target: container; anchors.leftMargin: 0 }
            }
        ]
        transitions: [
            Transition {
                to: "*"
                NumberAnimation { target: container; properties: "anchors.leftMargin"; duration: 300; easing.type: Easing.InOutQuad; }
            }
        ]
    }
}
