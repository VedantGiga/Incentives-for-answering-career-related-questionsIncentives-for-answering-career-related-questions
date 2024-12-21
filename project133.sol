// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CareerQuestionIncentives {
    struct Question {
        address asker;
        string content;
        uint256 reward;
        bool isAnswered;
    }

    struct Answer {
        address responder;
        string content;
    }

    uint256 public questionCount;
    mapping(uint256 => Question) public questions;
    mapping(uint256 => Answer) public answers;

    event QuestionPosted(uint256 questionId, address indexed asker, uint256 reward);
    event AnswerSubmitted(uint256 questionId, address indexed responder);
    event RewardClaimed(uint256 questionId, address indexed responder, uint256 reward);

    modifier onlyAsker(uint256 questionId) {
        require(questions[questionId].asker == msg.sender, "Not the asker.");
        _;
    }

    modifier questionExists(uint256 questionId) {
        require(questionId < questionCount, "Invalid question ID.");
        _;
    }

    function postQuestion(string memory content) external payable {
        require(msg.value > 0, "Reward must be greater than 0.");

        questions[questionCount] = Question({
            asker: msg.sender,
            content: content,
            reward: msg.value,
            isAnswered: false
        });

        emit QuestionPosted(questionCount, msg.sender, msg.value);
        questionCount++;
    }

    function submitAnswer(uint256 questionId, string memory content)
        external
        questionExists(questionId)
    {
        Question storage question = questions[questionId];
        require(!question.isAnswered, "Question already answered.");

        answers[questionId] = Answer({
            responder: msg.sender,
            content: content
        });

        question.isAnswered = true;

        emit AnswerSubmitted(questionId, msg.sender);
    }

    function claimReward(uint256 questionId)
        external
        questionExists(questionId)
        onlyAsker(questionId)
    {
        Question storage question = questions[questionId];
        require(question.isAnswered, "Question not answered yet.");

        Answer storage answer = answers[questionId];
        uint256 reward = question.reward;

        question.reward = 0; // Prevent reentrancy
        payable(answer.responder).transfer(reward);

        emit RewardClaimed(questionId, answer.responder, reward);
    }
}
