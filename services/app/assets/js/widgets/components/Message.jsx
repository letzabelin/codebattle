import React from 'react';
import { useSelector } from 'react-redux';
import moment from 'moment';
import { currentUserIsAdminSelector } from '../selectors';
import { pushCommand } from '../middlewares/Chat';

const Message = ({
 text = '', name = '', type, time,
}) => {
  const currentUserIsAdmin = useSelector(state => currentUserIsAdminSelector(state));
  const handleBanClick = bannedName => {
    pushCommand({ type: 'ban', name: bannedName });
  };

  if (!text) {
    return null;
  }

  if (type === 'info') {
    return (
      <div className="d-flex align-items-baseline flex-wrap">
        <small className="text-muted text-small">{text}</small>
        <small className="text-muted text-small ml-auto">{time ? moment.unix(time).format('HH:mm:ss') : ''}</small>
      </div>
    );
  }

  const parts = text.split(/(@+[-a-zA-Z0-9_]+\b)/g);

  const renderMessagePart = (part, i) => {
    if (part.slice(1) === name) {
      return (
        <span key={i} className="font-weight-bold bg-warning">
          {part}
        </span>
      );
    }
    if (part.startsWith('@')) {
      return (
        <span key={i} className="font-weight-bold text-primary">
          {part}
        </span>
      );
    }
    return part;
  };

  return (
    <div className="d-flex align-items-baseline flex-wrap">
      {/* eslint-disable-next-line react/no-array-index-key */}
      <span className="font-weight-bold">{`${name}: `}</span>
      <span className="ml-1">{parts.map((part, i) => renderMessagePart(part, i))}</span>
      <small className="text-muted text-small ml-auto">{time ? moment.unix(time).format('HH:mm:ss') : ''}</small>
      {currentUserIsAdmin ? (
        <button
          type="button"
          className="btn btn-sm btn-link text-danger"
          onClick={() => {
            handleBanClick(name);
          }}
        >
          Ban
        </button>
      ) : null}
    </div>
  );
};

export default Message;
