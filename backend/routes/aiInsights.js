const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const DailyLog = require('../models/DailyLog');
const Task = require('../models/Task');

router.get('/', auth, async (req, res) => {
  try {
    const tasks = await Task.find({ user: req.user.id, isActive: true });
    const logs = await DailyLog.find({ user: req.user.id })
      .sort('-date')
      .limit(7);
    
    const insights = [];
    
    if (tasks.length === 0) {
      insights.push({
        type: 'tip',
        message: 'Add your first habit to start your 21-day journey!',
      });
    } else {
      // Calculate completion rates
      const taskStats = {};
      tasks.forEach(t => { taskStats[t._id] = { title: t.title, total: 0, completed: 0 }; });
      
      logs.forEach(log => {
        log.completions.forEach(c => {
          if (taskStats[c.taskId]) {
            taskStats[c.taskId].total++;
            if (c.completed) taskStats[c.taskId].completed++;
          }
        });
      });
      
      const best = Object.values(taskStats)
        .filter(t => t.total > 0)
        .sort((a, b) => (b.completed / b.total) - (a.completed / a.total))[0];
      
      if (best) {
        const rate = Math.round((best.completed / best.total) * 100);
        insights.push({
          type: 'positive',
          message: `Great job with "${best.title}"! ${rate}% completion rate. Keep it up!`,
        });
      }
      
      insights.push({
        type: 'tip',
        message: 'Set a specific time each day for your habits. Consistency beats intensity!',
      });
    }
    
    res.json({ insights });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;