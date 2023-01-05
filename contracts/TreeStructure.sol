pragma solidity 0.8.12;


contract TreeStructure {


mapping(address => mapping(uint => TreeNode)) internal tree;


struct TreeNode {
    uint value;
    address[] children;
}


function updateNodeValue(address node, uint period,  uint value) internal {
    TreeNode storage targetNode = tree[node][period];

    targetNode.value = value;
}


function addChildNode(address parent, uint period, uint value, address child) internal {
    TreeNode storage parentNode = tree[parent][period];

    tree[child][period] = TreeNode({ value: value, children: new address[](0) });

    parentNode.children.push(child);
}


function sumChildrenValues(address root, uint _period) public view returns (uint256 totalValue) {
    if (tree[root][_period].children.length == 0) {
        return tree[root][_period].value;
    }

    // Recursive case: sum up the values of all the children of the current node
    totalValue = tree[root][_period].value;
    for (uint256 i = 0; i < tree[root][_period].children.length; i++) {
        address child = tree[root][_period].children[i];
        totalValue += sumChildrenValues(child, _period);
    }
    return totalValue;
}

function countChildren(address parent, uint period) public view returns (uint count) {
    TreeNode storage parentNode = tree[parent][period];

    if (parentNode.children.length == 0) {
        return 0;
    }

    // Recursive case: sum up the children of the parent node and all its children
    count = parentNode.children.length;
    for (uint256 i = 0; i < parentNode.children.length; i++) {
        address child = parentNode.children[i];
        count += countChildren(child, period);
    }
    return count;
}

function nodeExists(address node, uint period) public view returns (bool) {
    return tree[node][period].value != 0;
}


function nodeHasChild(address node, uint period, address child) public view returns (bool) {
    for (uint i = 0; i < tree[node][period].children.length; i++) {
    if (tree[node][period].children[i] == child) {
    return true;
}
}
    return false;
}


function traverseTree(address root, uint _period) public view returns (uint256 totalValue) {
    // Retrieve the root node from the tree mapping
    TreeNode storage rootNode = tree[root][_period];

    // Base case: if the root node has no children, return its value
    if (rootNode.children.length == 0) {
        return rootNode.value;
    }

    // Recursive case: sum up the values of all the children of the root node
    totalValue = rootNode.value;
    for (uint256 i = 0; i < rootNode.children.length; i++) {
        address child = rootNode.children[i];
        if (!hasMorePointsThanParent(root, child, _period)) { // check if child has more points than parent
            totalValue += traverseTree(child, _period);
        }
    }
    return totalValue;
}

function hasMorePointsThanParent(address parent, address child, uint period) public view returns (bool) {
    // Retrieve the parent and child nodes from the tree mapping
    TreeNode storage parentNode = tree[parent][period];
    TreeNode storage childNode = tree[child][period];

    // Sum up the values of all the children of the parent node
    uint parentCumulativePoints = parentNode.value;
    for (uint i = 0; i < parentNode.children.length; i++) {
        address grandchild = parentNode.children[i];
        parentCumulativePoints += tree[grandchild][period].value;
    }

    // Compare the cumulative points of the parent node with the value of the child node
    if (parentCumulativePoints > childNode.value) {
        return false; // parent has more points
    } else {
        return true; // child has more points
    }
}



}